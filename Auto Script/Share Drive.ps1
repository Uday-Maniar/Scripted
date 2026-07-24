# --- SELF-ELEVATION ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- INPUT ---
$driveLetter = Read-Host "Which Drive do you want to share? (D, E, F, G)"
$drivePath = "${driveLetter}:\"
$shareName = "${driveLetter}"

if (!(Test-Path $drivePath)) { 
    Write-Host "Error: Drive $drivePath not found!" -ForegroundColor Red
    Pause; return 
}

# --- STEP 1: OWNERSHIP ---
Write-Host "Taking ownership of $drivePath..." -ForegroundColor Yellow
takeown /F $drivePath /A /R /D Y

# --- STEP 2: SECURITY TAB (NTFS) ---
Write-Host "Assigning Security Tab permissions..." -ForegroundColor Cyan
# Using standard names for clarity, but adding Administrator explicitly
$identities = @("Everyone", "Administrators", "Administrator", "Authenticated Users", "Users")

foreach ($id in $identities) {
    icacls $drivePath /grant:r "${id}:(OI)(CI)F" /T /C /Q
}

# --- STEP 3: SHARING TAB (SMB) ---
Write-Host "Assigning Sharing Tab permissions..." -ForegroundColor Cyan

# Remove any existing share for this name or path to avoid "Access Denied"
Get-SmbShare | Where-Object { $_.Name -eq $shareName -or $_.Path -eq $drivePath } | Remove-SmbShare -Force -ErrorAction SilentlyContinue

# Create new share with all 5 identities
New-SmbShare -Name $shareName -Path $drivePath -FullAccess $identities

Write-Host "`n--- SUCCESS! ---" -ForegroundColor Green
Write-Host "Drive $drivePath is now shared as '$shareName' with Full Control for all groups."
Pause