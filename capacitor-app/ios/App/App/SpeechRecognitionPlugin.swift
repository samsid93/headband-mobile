import Foundation
import AVFoundation
import Capacitor
import Speech

/// Native speech recognition for the voice-guess mode (QA M-010 … M-015).
///
/// WHY THIS FILE EXISTS
/// Neither WKWebView nor Android WebView exposes the Web Speech API, so
/// `window.SpeechRecognition` is undefined inside the app and every spoken
/// "correct" / "skip" was ignored. Android gets this from
/// @capacitor-community/speech-recognition. iOS cannot: that package ships a
/// CocoaPods podspec and no Package.swift, and this project builds with SPM, so
/// `cap sync` skips its native half entirely ("does not have a Package.swift").
///
/// This is a port of that plugin's iOS implementation into the app target,
/// where SPM is not involved. It deliberately keeps the SAME JS surface and the
/// same event names, so headband-game-web.html talks to one API on both
/// platforms and neither side needs a special case.
///
/// Registration is via CAPBridgedPlugin rather than the CAP_PLUGIN macro in an
/// Objective-C .m file — a mixed Swift/ObjC target is exactly what stops the
/// upstream package from being SPM-compatible in the first place.
///
/// Both Info.plist strings are load-bearing: NSMicrophoneUsageDescription AND
/// NSSpeechRecognitionUsageDescription. They are separate consents, and missing
/// the speech one is a hard crash the moment recognition starts, not a denial.
@objc(SpeechRecognition)
public class SpeechRecognition: CAPPlugin, CAPBridgedPlugin {

    public let identifier = "SpeechRecognition"
    public let jsName = "SpeechRecognition"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "available", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "start", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stop", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getSupportedLanguages", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isListening", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "checkPermissions", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestPermissions", returnType: CAPPluginReturnPromise)
    ]

    private let defaultMatches = 5
    private let messageMissingPermission = "Missing permission"
    private let messageAccessDeniedMicrophone = "User denied access to microphone"
    private let messageOngoing = "Ongoing speech recognition"
    private let messageUnknown = "Unknown error occurred"

    private var speechRecognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    @objc func available(_ call: CAPPluginCall) {
        guard let recognizer = SFSpeechRecognizer() else {
            call.resolve(["available": false])
            return
        }
        call.resolve(["available": recognizer.isAvailable])
    }

    @objc func start(_ call: CAPPluginCall) {
        if let engine = audioEngine, engine.isRunning {
            call.reject(messageOngoing)
            return
        }
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            call.reject(messageMissingPermission)
            return
        }

        requestMicPermission { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                call.reject(self.messageAccessDeniedMicrophone)
                return
            }
            DispatchQueue.main.async {
                self.beginSession(call)
            }
        }
    }

    private func beginSession(_ call: CAPPluginCall) {
        let language = call.getString("language") ?? "en-US"
        let maxResults = call.getInt("maxResults") ?? defaultMatches
        let partialResults = call.getBool("partialResults") ?? false

        recognitionTask?.cancel()
        recognitionTask = nil

        audioEngine = AVAudioEngine()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language))

        // mixWithOthers keeps the game's own sound effects audible while the mic
        // is live — playAndRecord alone ducks them to silence mid-round.
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            call.reject("Microphone is already in use by another application.")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = partialResults

        guard let engine = audioEngine, let request = recognitionRequest else {
            call.reject(messageUnknown)
            return
        }

        // With partialResults the call is resolved as soon as the engine starts,
        // so anything later must go out as an event. Rejecting a settled call is
        // a no-op that silently swallows the error.
        var settled = false

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                var matches: [String] = []
                for transcription in result.transcriptions {
                    if maxResults > 0 && matches.count < maxResults {
                        matches.append(transcription.formattedString)
                    }
                }
                if partialResults {
                    self.notifyListeners("partialResults", data: ["matches": matches])
                } else if !settled {
                    settled = true
                    call.resolve(["matches": matches])
                }
                if result.isFinal {
                    self.teardown()
                }
            }

            if error != nil {
                self.teardown()
                if !settled {
                    settled = true
                    call.reject(error!.localizedDescription)
                }
            }
        }

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
            notifyListeners("listeningState", data: ["status": "started"])
            if partialResults && !settled {
                settled = true
                call.resolve()
            }
        } catch {
            teardown()
            if !settled {
                settled = true
                call.reject(messageUnknown)
            }
        }
    }

    /// Stops the engine and tells JS. The web layer listens for the "stopped"
    /// event and starts a fresh session, which is what keeps listening
    /// continuous — iOS caps any single recognition session at about a minute.
    private func teardown() {
        if let engine = audioEngine {
            if engine.isRunning { engine.stop() }
            engine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest = nil
        recognitionTask = nil
        notifyListeners("listeningState", data: ["status": "stopped"])
    }

    @objc func stop(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if let engine = self.audioEngine, engine.isRunning {
                engine.stop()
                self.recognitionRequest?.endAudio()
                engine.inputNode.removeTap(onBus: 0)
                self.notifyListeners("listeningState", data: ["status": "stopped"])
            }
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
            self.recognitionRequest = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            call.resolve()
        }
    }

    @objc func isListening(_ call: CAPPluginCall) {
        call.resolve(["listening": audioEngine?.isRunning ?? false])
    }

    @objc func getSupportedLanguages(_ call: CAPPluginCall) {
        let languages = SFSpeechRecognizer.supportedLocales().map { $0.identifier }
        call.resolve(["languages": languages])
    }

    @objc override public func checkPermissions(_ call: CAPPluginCall) {
        let permission: String
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:    permission = "granted"
        case .denied,
             .restricted:    permission = "denied"
        case .notDetermined: permission = "prompt"
        @unknown default:    permission = "prompt"
        }
        call.resolve(["speechRecognition": permission])
    }

    /// One JS-facing alias covering both consents: speech recognition first,
    /// then the microphone. Granting only one still cannot listen, so the alias
    /// reports "granted" only when both are in.
    @objc override public func requestPermissions(_ call: CAPPluginCall) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.requestMicPermission { granted in
                        DispatchQueue.main.async {
                            call.resolve(["speechRecognition": granted ? "granted" : "denied"])
                        }
                    }
                default:
                    self.checkPermissions(call)
                }
            }
        }
    }

    /// AVAudioSession.requestRecordPermission is deprecated from iOS 17; the
    /// deployment target is still iOS 15, so both paths have to stay.
    private func requestMicPermission(_ completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: completion)
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission(completion)
        }
    }
}
