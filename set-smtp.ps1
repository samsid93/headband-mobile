# Wham Bam — configure custom SMTP on the hosted Supabase project via the
# Management API. Unlocks email-template editing AND de-brands the sender.
# SURGICAL PATCH — only the SMTP fields are changed.
#
# Set these env vars first (values from your SMTP provider, e.g. Resend):
#   $env:SUPABASE_ACCESS_TOKEN = "<Supabase PAT>"
#   $env:SMTP_HOST         = "smtp.resend.com"
#   $env:SMTP_PORT         = "465"
#   $env:SMTP_USER         = "resend"
#   $env:SMTP_PASS         = "<smtp password / API key>"
#   $env:SMTP_SENDER_EMAIL = "no-reply@whambam.games"
#   $env:SMTP_SENDER_NAME  = "Wham Bam"
# Then:  .\set-smtp.ps1

$ErrorActionPreference = "Stop"
$ref   = "izxzlxtowubbjiatouci"
$token = $env:SUPABASE_ACCESS_TOKEN
if ([string]::IsNullOrWhiteSpace($token)) { Write-Error 'Set $env:SUPABASE_ACCESS_TOKEN first.'; exit 1 }

$req = "SMTP_HOST","SMTP_PORT","SMTP_USER","SMTP_PASS","SMTP_SENDER_EMAIL","SMTP_SENDER_NAME"
foreach ($v in $req) {
  if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($v))) {
    Write-Error "Missing env var: $v"; exit 1
  }
}

Add-Type -AssemblyName System.Web.Extensions
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$payload = $ser.Serialize(@{
  smtp_admin_email = $env:SMTP_SENDER_EMAIL
  smtp_host        = $env:SMTP_HOST
  smtp_port        = "$($env:SMTP_PORT)"
  smtp_user        = $env:SMTP_USER
  smtp_pass        = $env:SMTP_PASS
  smtp_sender_name = $env:SMTP_SENDER_NAME
})
$bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)

$uri = "https://api.supabase.com/v1/projects/$ref/config/auth"
Write-Host "Configuring custom SMTP ($($env:SMTP_HOST))..." -ForegroundColor Cyan
$resp = Invoke-RestMethod -Method Patch -Uri $uri `
  -Headers @{ Authorization = "Bearer $token" } `
  -ContentType "application/json; charset=utf-8" -Body $bytes
Write-Host "Done. Sender: $($resp.smtp_sender_name) <$($resp.smtp_admin_email)>" -ForegroundColor Green
Write-Host "Now run .\update-auth-email.ps1 to apply the branded template."
