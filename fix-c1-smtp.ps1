# ─────────────────────────────────────────────────────────────────────────────
# C-1 FIX — restore the SMTP credentials Supabase uses to send confirmation
# emails, then PROVE signup works again.
#
# Diagnosis this addresses (verified 30 Jul 2026):
#   POST /auth/v1/signup -> 500 "Error sending confirmation email"
#   smtp.hostinger.com:465 reachable, TLS 1.3, AUTH PLAIN LOGIN advertised
#   AUTH no-reply@whambam.games -> 535 authentication failed
#   => Supabase holds a mailbox password that no longer authenticates.
#
# Set these in the SAME shell, then run this script:
#   $env:SUPABASE_ACCESS_TOKEN = "<fresh Supabase PAT>"
#   $env:SMTP_PASS             = "<CURRENT no-reply@whambam.games password>"
# Optional overrides (defaults shown):
#   $env:SMTP_HOST = "smtp.hostinger.com"
#   $env:SMTP_PORT = "465"
#   $env:SMTP_USER = "no-reply@whambam.games"
#
# Secrets are read from the environment only — never written to this file or logged.
# ─────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"
$ref  = "izxzlxtowubbjiatouci"
$anon = "sb_publishable_Q6pr9JEFYrhUuQvnojz1Mg_MbPuinDh"   # public client key

$token = $env:SUPABASE_ACCESS_TOKEN
$pass  = $env:SMTP_PASS
$smtpHost = if ($env:SMTP_HOST) { $env:SMTP_HOST } else { "smtp.hostinger.com" }
$smtpPort = if ($env:SMTP_PORT) { $env:SMTP_PORT } else { "465" }
$smtpUser = if ($env:SMTP_USER) { $env:SMTP_USER } else { "no-reply@whambam.games" }

if ([string]::IsNullOrWhiteSpace($token)) { Write-Error 'Set $env:SUPABASE_ACCESS_TOKEN first.'; exit 1 }
if ([string]::IsNullOrWhiteSpace($pass))  { Write-Error 'Set $env:SMTP_PASS first.'; exit 1 }

Write-Host ""
Write-Host "STEP 1/4  Confirming the failure is still present..." -ForegroundColor Cyan
$probe = "qa.pre.$([DateTimeOffset]::Now.ToUnixTimeSeconds())@whambam.games"
$body  = @{ email = $probe; password = "DiagTest12345!" } | ConvertTo-Json -Compress
try {
  Invoke-RestMethod -Method Post -Uri "https://$ref.supabase.co/auth/v1/signup" `
    -Headers @{ apikey = $anon } -ContentType "application/json" -Body $body | Out-Null
  Write-Host "  Signup already succeeds — SMTP may already be fixed. Continuing anyway." -ForegroundColor Yellow
} catch {
  $code = $_.Exception.Response.StatusCode.value__
  Write-Host "  Confirmed: signup returns HTTP $code" -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "STEP 2/4  Verifying the mailbox password against $smtpHost..." -ForegroundColor Cyan
# Authenticate directly, so a bad password is caught HERE rather than surfacing
# later as another opaque 500 from Supabase.
$client = New-Object System.Net.Mail.SmtpClient($smtpHost, [int]$smtpPort)
$client.EnableSsl = $true
$client.Credentials = New-Object System.Net.NetworkCredential($smtpUser, $pass)
$authOk = $false
try {
  # A null recipient send forces AUTH without delivering anything.
  $client.Timeout = 15000
  $msg = New-Object System.Net.Mail.MailMessage($smtpUser, $smtpUser, "WhamBam SMTP check", "ok")
  $client.Send($msg)
  $authOk = $true
  Write-Host "  AUTH OK — credentials accepted (a test mail was sent to $smtpUser)" -ForegroundColor Green
} catch {
  Write-Host "  AUTH FAILED — $($_.Exception.Message)" -ForegroundColor Red
  Write-Host ""
  Write-Host "  The password in `$env:SMTP_PASS is not accepted by Hostinger." -ForegroundColor Red
  Write-Host "  Fix in hPanel > Emails > no-reply@whambam.games, then re-run." -ForegroundColor Red
  Write-Host "  Not pushing a credential that is already known bad." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "STEP 3/4  Pushing SMTP config to Supabase..." -ForegroundColor Cyan
Add-Type -AssemblyName System.Web.Extensions
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$payload = $ser.Serialize(@{
  smtp_admin_email = $smtpUser
  smtp_host        = $smtpHost
  smtp_port        = "$smtpPort"      # must be a string, not an int
  smtp_user        = $smtpUser
  smtp_pass        = $pass
  smtp_sender_name = "Wham Bam"
})
$bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
$resp = Invoke-RestMethod -Method Patch -Uri "https://api.supabase.com/v1/projects/$ref/config/auth" `
  -Headers @{ Authorization = "Bearer $token" } `
  -ContentType "application/json; charset=utf-8" -Body $bytes
Write-Host "  Sender is now: $($resp.smtp_sender_name) <$($resp.smtp_admin_email)>" -ForegroundColor Green

Write-Host ""
Write-Host "STEP 4/4  Re-testing signup (allowing 8s for config to propagate)..." -ForegroundColor Cyan
Start-Sleep -Seconds 8
$probe2 = "qa.post.$([DateTimeOffset]::Now.ToUnixTimeSeconds())@whambam.games"
$body2  = @{ email = $probe2; password = "DiagTest12345!" } | ConvertTo-Json -Compress
try {
  Invoke-RestMethod -Method Post -Uri "https://$ref.supabase.co/auth/v1/signup" `
    -Headers @{ apikey = $anon } -ContentType "application/json" -Body $body2 | Out-Null
  Write-Host ""
  Write-Host "  C-1 RESOLVED — signup returned 200 and the confirmation email sent." -ForegroundColor Green
  Write-Host "  Test account created: $probe2 (delete it in Dashboard > Authentication > Users)" -ForegroundColor DarkGray
  Write-Host ""
  Write-Host "  Next: rotate BOTH secrets you just pasted into the chat session." -ForegroundColor Yellow
} catch {
  $code = $_.Exception.Response.StatusCode.value__
  $detail = ""
  try {
    $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $detail = $sr.ReadToEnd()
  } catch {}
  Write-Host ""
  Write-Host "  STILL FAILING — HTTP $code" -ForegroundColor Red
  Write-Host "  $detail" -ForegroundColor Red
  Write-Host ""
  Write-Host "  SMTP auth passed in step 2, so the credential is good and the" -ForegroundColor Yellow
  Write-Host "  remaining fault is Supabase-side. Check Dashboard > Logs > Auth" -ForegroundColor Yellow
  Write-Host "  for the specific SMTP error on this attempt." -ForegroundColor Yellow
  exit 1
}
