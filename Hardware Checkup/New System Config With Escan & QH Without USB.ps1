# ==========================================
# 1. Initialize Excel and Setup Headers
# ==========================================
$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $true
$Workbook = $Excel.Workbooks.Add()
$Sheet = $Workbook.Worksheets.Item(1)

$Headers = "Sr.No.", "User Name", "Operating System", "Motherboard", "Processor", "Ram", "Harddisk", "Monitor", "Antivirus", "Expiry Date", "Product Key", "Laptop Serial No."
for ($i = 0; $i -lt $Headers.Count; $i++) {
    $Sheet.Cells.Item(1, $i + 1) = $Headers[$i]
}

# ==========================================
# 2. Collect System Data & Antivirus Priority
# ==========================================
$OSInfo = Get-CimInstance Win32_OperatingSystem
$ComputerInfo = Get-CimInstance Win32_ComputerSystem
$Board = Get-CimInstance Win32_BaseBoard
$CPU = Get-CimInstance Win32_Processor
$BIOS = Get-CimInstance Win32_BIOS

# Get AV products and Filter OUT Windows Defender if others exist
$AVProducts = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct
$ActiveAV = $AVProducts | Where-Object { $_.displayName -notlike "*Windows Defender*" } | Select-Object -First 1
if (-not $ActiveAV) { $ActiveAV = $AVProducts | Select-Object -First 1 }

$Antivirus = if ($ActiveAV) { $ActiveAV.displayName } else { "Not Found" }
$ProductKey = "N/A"

# ==========================================
# 3. Product Key Extraction (eScan or Quick Heal)
# ==========================================

# --- Logic for eScan ---
if ($Antivirus -like "*eScan*") {
    $eScanPath = "${env:ProgramFiles(x86)}\eScan\license.ini"
    if (-not (Test-Path $eScanPath)) { $eScanPath = "C:\Program Files\eScan\license.ini" }
    
    if (Test-Path $eScanPath) {
        $lines = Get-Content $eScanPath | Where-Object { $_ -match "^RegKey\d+=" }
        if ($lines) {
            $latestKeyLine = $lines | Sort-Object | Select-Object -Last 1
            $rawKey = ($latestKeyLine -split "=")[1].Trim()
            $ProductKey = if ($rawKey.Length -ge 37) { $rawKey.Substring(0, 37) } else { $rawKey }
        }
    }
}

# --- Logic for Quick Heal ---
elseif ($Antivirus -like "*Quick Heal*") {
    $qhPaths = @("${env:ProgramFiles(x86)}\Quick Heal", "C:\Program Files\Quick Heal")
    foreach ($path in $qhPaths) {
        if (Test-Path $path) {
            $iniFile = Get-ChildItem -Path $path -Filter "userinfo.ini" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($iniFile) {
                $qhContent = Get-Content $iniFile.FullName
                $keyLine = $qhContent | Where-Object { $_ -match "^Product Key=" }
                if ($keyLine) { $ProductKey = ($keyLine -split "=")[1].Trim() }
            }
            break
        }
    }
}

# ==========================================
# 4. Write Core Data to Row 2
# ==========================================
$Sheet.Cells.Item(2, 1) = 1
$Sheet.Cells.Item(2, 2) = $ComputerInfo.UserName
$Sheet.Cells.Item(2, 3) = "$($OSInfo.Caption) ($($OSInfo.OSArchitecture))"
$Sheet.Cells.Item(2, 4) = "$($Board.Manufacturer.Trim()) $($Board.Product.Trim())"
$Sheet.Cells.Item(2, 5) = $CPU.Name
$Sheet.Cells.Item(2, 9) = $Antivirus
$Sheet.Cells.Item(2, 11) = $ProductKey
$Sheet.Cells.Item(2, 12) = $BIOS.SerialNumber

# ==========================================
# 5. Handle Components (RAM, Internal Disks, Monitor)
# ==========================================

# RAM Modules
$RAMModules = Get-CimInstance Win32_PhysicalMemory
$RAMRow = 2
foreach ($Module in $RAMModules) {
    $CapGB = [math]::Round($Module.Capacity / 1GB)
    $DDR = switch ($Module.SMBIOSMemoryType) {
        20 { "DDR" } 21 { "DDR2" } 24 { "DDR3" } 26 { "DDR4" } 34 { "DDR5" } default { "DDR/Unknown" }
    }
    $Sheet.Cells.Item($RAMRow, 6) = "$($Module.Manufacturer) $($CapGB)GB $DDR $($Module.ConfiguredClockSpeed)MHz"
    $RAMRow++
}

# Internal Harddisks (Excluding USB/External)
$Disks = Get-PhysicalDisk | Where-Object { $_.BusType -ne "USB" }
$DiskRow = 2
foreach ($Disk in $Disks) {
    $SizeGB = [math]::Round($Disk.Size / 1GB)
    $Type = if ($Disk.MediaType -eq "UnSpecified") { "SATA/HDD" } else { $Disk.MediaType }
    $Sheet.Cells.Item($DiskRow, 7) = "$($Disk.FriendlyName) ($Type) - $($SizeGB)GB"
    $DiskRow++
}

# Monitor Info
try {
    $m = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue
    $p = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction SilentlyContinue
    if ($m) {
        $mfg = [System.Text.Encoding]::ASCII.GetString($m.ManufacturerName -notmatch 0).Trim()
        $model = [System.Text.Encoding]::ASCII.GetString($m.UserFriendlyName -notmatch 0).Trim()
        $diag = [Math]::Round(([Math]::Sqrt([Math]::Pow($p.MaxHorizontalImageSize, 2) + [Math]::Pow($p.MaxVerticalImageSize, 2))) / 2.54, 1)
        $Sheet.Cells.Item(2, 8) = "$mfg - $model ($diag Inches)"
    }
} catch { $Sheet.Cells.Item(2, 8) = "Internal/N/A" }

# ==========================================
# 6. Finalize Formatting
# ==========================================
$Sheet.Rows.Item(1).Font.Bold = $true
$Sheet.Columns.AutoFit()

Write-Host "Inventory Finished! Internal Disks Counted: $($Disks.Count)" -ForegroundColor Green