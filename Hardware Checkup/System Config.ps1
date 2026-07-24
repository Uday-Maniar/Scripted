# 1. Initialize Excel and Setup Headers
$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $true
$Workbook = $Excel.Workbooks.Add()
$Sheet = $Workbook.Worksheets.Item(1)

# Set Headers in Row 2
$Headers = "Sr.No.", "User Name", "Operating System", "Motherboard", "Processor", "Ram", "Harddisk", "Monitor", "Antivirus", "Expiry Date", "Product Key"
for ($i = 0; $i -lt $Headers.Count; $i++) {
    $Sheet.Cells.Item(2, $i + 1) = $Headers[$i]
}

# 2. Collect Data
# Basic Info
$OSInfo = Get-CimInstance Win32_OperatingSystem
$ComputerInfo = Get-CimInstance Win32_ComputerSystem
$Board = Get-CimInstance Win32_BaseBoard
$CPU = Get-CimInstance Win32_Processor
$AVInfo = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct

# Formatting Strings
$OSString = "$($OSInfo.Caption) ($($OSInfo.OSArchitecture))"
$MoboString = "$($Board.Manufacturer.Trim()) $($Board.Product.Trim())"
$CPUString = $CPU.Name
$UserName = $ComputerInfo.UserName
$Antivirus = $AVInfo.displayName

# 3. Write Static Data to Row 3
$Sheet.Cells.Item(3, 1) = 1                # Sr.No.
$Sheet.Cells.Item(3, 2) = $UserName         # User Name
$Sheet.Cells.Item(3, 3) = $OSString         # Operating System
$Sheet.Cells.Item(3, 4) = $MoboString       # Motherboard
$Sheet.Cells.Item(3, 5) = $CPUString        # Processor
$Sheet.Cells.Item(3, 9) = $Antivirus        # Antivirus

# 4. Handle Multiple RAM Modules (Column F / 6)
$RAMModules = Get-CimInstance Win32_PhysicalMemory
$RAMRow = 3
foreach ($Module in $RAMModules) {
    $CapGB = [math]::Round($Module.Capacity / 1GB)
    $Speed = $Module.ConfiguredClockSpeed
    $DDR = switch ($Module.SMBIOSMemoryType) {
        20 { "DDR" } 21 { "DDR2" } 24 { "DDR3" } 26 { "DDR4" } 34 { "DDR5" } default { "DDR/Unknown" }
    }
    $Sheet.Cells.Item($RAMRow, 6) = "$($Module.Manufacturer) $($CapGB)GB $DDR $($Speed)MHz"
    $RAMRow++
}

# 5. Handle Multiple Harddisks (Column G / 7)
$Disks = Get-PhysicalDisk
$DiskRow = 3
foreach ($Disk in $Disks) {
    $SizeGB = [math]::Round($Disk.Size / 1GB)
    $Type = if ($Disk.MediaType -eq "UnSpecified") { "SATA/HDD" } else { $Disk.MediaType }
    $Sheet.Cells.Item($DiskRow, 7) = "$($Disk.FriendlyName) ($Type) - $($SizeGB)GB"
    $DiskRow++
}

# 6. Handle Monitor (Column H / 8)
try {
    $m = Get-WmiObject -Namespace root\wmi -Class WmiMonitorID -ErrorAction SilentlyContinue
    $p = Get-WmiObject -Namespace root\wmi -Class WmiMonitorBasicDisplayParams -ErrorAction SilentlyContinue
    if ($m) {
        $mfg = [System.Text.Encoding]::ASCII.GetString($m.ManufacturerName -notmatch 0).Trim()
        $model = [System.Text.Encoding]::ASCII.GetString($m.UserFriendlyName -notmatch 0).Trim()
        $diag = [Math]::Round(([Math]::Sqrt([Math]::Pow($p.MaxHorizontalImageSize, 2) + [Math]::Pow($p.MaxVerticalImageSize, 2))) / 2.54, 1)
        $Sheet.Cells.Item(3, 8) = "$mfg - $model ($diag Inches)"
    }
} catch {
    $Sheet.Cells.Item(3, 8) = "Monitor Info Not Found"
}

# 7. Cleanup & Formatting
$Sheet.Rows.Item(2).Font.Bold = $true
$Sheet.Columns.AutoFit()

Write-Host "Inventory Complete!" -ForegroundColor Green