package games.whambam.app;

import android.content.pm.ActivityInfo;
import android.os.Bundle;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;

import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {

    /**
     * Exposed to the web page as window.AndroidBridge.
     *
     * The @capacitor/screen-orientation plugin is the primary route now (it is the
     * only one that works on iOS), but this stays as the Android fallback:
     * FULL_SENSOR is the one mode that overrides an OEM system rotation lock,
     * which the plugin does not guarantee.
     */
    private class AndroidBridge {
        @JavascriptInterface
        public void unlockOrientation() {
            runOnUiThread(() -> setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_FULL_SENSOR));
        }

        @JavascriptInterface
        public void lockLandscape() {
            runOnUiThread(() -> setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE));
        }

        @JavascriptInterface
        public void resetOrientation() {
            runOnUiThread(() -> setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR));
        }
    }

    /**
     * Full-screen immersive: hide the status and navigation bars, letting a swipe
     * reveal them transiently.
     *
     * Applying this once in onCreate() is not enough — Android restores the bars
     * on every focus change (after the launch splash, after the keyboard closes,
     * on return from the recents switcher), so it has to be re-applied whenever
     * the window regains focus.
     */
    private void applyImmersive() {
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        WindowInsetsControllerCompat controller =
            WindowCompat.getInsetsController(getWindow(), getWindow().getDecorView());
        controller.setSystemBarsBehavior(
            WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        );
        controller.hide(WindowInsetsCompat.Type.systemBars());
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) applyImmersive();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        applyImmersive();

        WebView webView = getBridge().getWebView();

        // Expose native orientation control to the web page
        webView.addJavascriptInterface(new AndroidBridge(), "AndroidBridge");

        // Match browser scaling — Android WebView otherwise applies font inflation
        // and pinch zoom, which breaks the fixed game layout.
        webView.getSettings().setTextZoom(100);
        webView.getSettings().setUseWideViewPort(true);
        webView.getSettings().setLoadWithOverviewMode(false);
        webView.getSettings().setSupportZoom(false);
        webView.getSettings().setBuiltInZoomControls(false);
        webView.getSettings().setDisplayZoomControls(false);
    }
}
