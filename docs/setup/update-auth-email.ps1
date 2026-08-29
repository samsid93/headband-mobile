# Wham Bam — brand the "Confirm signup" email via the Supabase Management API.
# SURGICAL: this PATCH only updates the fields sent below; all other auth
# settings are left exactly as they are (unlike `supabase config push`).
#
# REQUIRES: a custom SMTP provider must be configured first (free-tier projects
# on the DEFAULT email provider cannot edit templates). See supabase-smtp-setup.txt.
#
# Usage (token stays out of the file / git):
#   $env:SUPABASE_ACCESS_TOKEN = "<Personal Access Token>"
#   .\update-auth-email.ps1
#   (get a token: Supabase Dashboard > Account > Access Tokens)

$ErrorActionPreference = "Stop"

$ref   = "izxzlxtowubbjiatouci"
$token = $env:SUPABASE_ACCESS_TOKEN
if ([string]::IsNullOrWhiteSpace($token)) {
  Write-Error 'Set the token first:  $env:SUPABASE_ACCESS_TOKEN = "<token>"'
  exit 1
}

$htmlPath = Join-Path $PSScriptRoot "supabase\templates\confirmation.html"
if (-not (Test-Path $htmlPath)) { $htmlPath = Join-Path $PSScriptRoot "whambam-confirm-email.html" }
if (-not (Test-Path $htmlPath)) { Write-Error "Email template not found."; exit 1 }
$html = [string](Get-Content -Path $htmlPath -Raw)

$subject = "Confirm your Wham Bam account " + [char]0xD83C + [char]0xDF89   # 🎉

# PS 5.1 ConvertTo-Json mangles long/typed strings ({value:} wrapping) and
# Invoke-RestMethod mis-encodes non-ASCII — use .NET serializer + UTF-8 bytes.
Add-Type -AssemblyName System.Web.Extensions
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = 50000000
$payload = $ser.Serialize(@{
  mailer_subjects_confirmation          = $subject
  mailer_templates_confirmation_content = $html
})
$bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)

$uri = "https://api.supabase.com/v1/projects/$ref/config/auth"
Write-Host "PATCHing confirm-signup email template + subject..." -ForegroundColor Cyan
$resp = Invoke-RestMethod -Method Patch -Uri $uri `
  -Headers @{ Authorization = "Bearer $token" } `
  -ContentType "application/json; charset=utf-8" -Body $bytes
Write-Host "Done." -ForegroundColor Green
Write-Host "Subject now: $($resp.mailer_subjects_confirmation)"
Write-Host "Template body length: $($resp.mailer_templates_confirmation_content.Length) chars"
