# ============================================================================
# PURE POWERSHELL COMBINED FIREWALL & HOSTS BLOCKER (MULTI-DRIVE ENABLED)
# ============================================================================

# Auto-relaunch with Administrator Privileges if not elevated
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$HostsPath = "$env:windir\System32\drivers\etc\hosts"

function Get-AllLocalDrives {
    # Detects all active local fixed drives (C:\, D:\, E:\, etc.)
    return Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null } | Select-Object -ExpandProperty Root
}

function AutoSearch-And-Block {
    param([string]$SoftwareName)
    
    $cleanName = $SoftwareName.Trim('"').Trim("'").Trim()
    if ([string]::IsNullOrWhiteSpace($cleanName)) { return }

    $allDrives = Get-AllLocalDrives
    Write-Host "`nDetected active drives: $($allDrives -join ', ')" -ForegroundColor Gray
    Write-Host "Scanning drives and folders for '$cleanName'..." -ForegroundColor Cyan

    $searchLocations = @()

    # Add standard software directories if they exist
    if (Test-Path $env:ProgramFiles) { $searchLocations += $env:ProgramFiles }
    if (Test-Path ${env:ProgramFiles(x86)}) { $searchLocations += ${env:ProgramFiles(x86)} }
    if (Test-Path $env:ProgramData) { $searchLocations += $env:ProgramData }
    if (Test-Path $env:LOCALAPPDATA) { $searchLocations += $env:LOCALAPPDATA }

    # Add root folders on ALL detected drives (excluding system/junk directories)
    foreach ($drive in $allDrives) {
        $rootFolders = Get-ChildItem -Path $drive -Directory -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -notmatch "^(Windows|\$Recycle\.Bin|System Volume Information|Recovery|Documents and Settings)$" } |
            Select-Object -ExpandProperty FullName
        $searchLocations += $rootFolders
    }

    # Find matching software folders across all locations
    $matchedFolders = @()
    foreach ($loc in $searchLocations) {
        if (Test-Path $loc) {
            if ((Split-Path $loc -Leaf) -like "*$cleanName*") {
                $matchedFolders += $loc
            }
            $foundDirs = Get-ChildItem -Path $loc -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*$cleanName*" }
            if ($foundDirs) {
                $matchedFolders += $foundDirs.FullName
            }
        }
    }

    $matchedFolders = $matchedFolders | Select-Object -Unique

    if ($matchedFolders.Count -eq 0) {
        Write-Host "[!] No installation folders found matching '$cleanName' across any drive." -ForegroundColor Yellow
        Write-Host "    (Use Option 2 to manually specify a custom path or drive letter like D:\)." -ForegroundColor DarkGray
        return
    }

    Write-Host "`nFound $($matchedFolders.Count) matching folder(s):" -ForegroundColor Yellow
    $matchedFolders | ForEach-Object { Write-Host " - $_" -ForegroundColor DarkGray }

    # Block executables inside found folders
    $count = 0
    foreach ($folder in $matchedFolders) {
        $exes = Get-ChildItem -Path $folder -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
        foreach ($exe in $exes) {
            $ruleOut = "Block_Out_" + $exe.Name
            $ruleIn  = "Block_In_" + $exe.Name
            
            Remove-NetFirewallRule -DisplayName $ruleOut -ErrorAction SilentlyContinue
            Remove-NetFirewallRule -DisplayName $ruleIn -ErrorAction SilentlyContinue
            
            New-NetFirewallRule -DisplayName $ruleOut -Direction Outbound -Program $exe.FullName -Action Block -Enabled True | Out-Null
            New-NetFirewallRule -DisplayName $ruleIn  -Direction Inbound  -Program $exe.FullName -Action Block -Enabled True | Out-Null
            
            $count++
            Write-Host "  [+] Blocked: $($exe.Name)" -ForegroundColor Green
        }
    }
    
    if ($count -gt 0) {
        Write-Host "`n[SUCCESS] Blocked $count executable(s) in Windows Firewall." -ForegroundColor Green
    } else {
        Write-Host "`n[!] Folders found, but no .exe files were detected inside." -ForegroundColor Yellow
    }
}

function Block-ManualFolder {
    param([string]$Path)
    
    $cleanPath = $Path.Trim('"').Trim("'").Trim()

    if (-not (Test-Path $cleanPath)) {
        Write-Host "`n[ERROR] Path does not exist: $cleanPath" -ForegroundColor Red
        return
    }

    Write-Host "`nScanning and blocking executables in path: $cleanPath" -ForegroundColor Cyan
    $exes = Get-ChildItem -Path $cleanPath -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
    
    if ($exes.Count -eq 0) {
        Write-Host "[!] No .exe files found in this path." -ForegroundColor Yellow
        return
    }

    $count = 0
    foreach ($exe in $exes) {
        $ruleOut = "Block_Out_" + $exe.Name
        $ruleIn  = "Block_In_" + $exe.Name
        
        Remove-NetFirewallRule -DisplayName $ruleOut -ErrorAction SilentlyContinue
        Remove-NetFirewallRule -DisplayName $ruleIn -ErrorAction SilentlyContinue
        
        New-NetFirewallRule -DisplayName $ruleOut -Direction Outbound -Program $exe.FullName -Action Block -Enabled True | Out-Null
        New-NetFirewallRule -DisplayName $ruleIn  -Direction Inbound  -Program $exe.FullName -Action Block -Enabled True | Out-Null
        
        $count++
        Write-Host "  [+] Blocked: $($exe.Name)" -ForegroundColor Green
    }
    Write-Host "`n[SUCCESS] Total executables blocked in Firewall: $count" -ForegroundColor Green
}

function Block-Domains {
    param([string]$VendorDomain)
    
    # Remove Read-Only attribute if present
    Set-ItemProperty -Path $HostsPath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue

    $clean = $VendorDomain.Replace(" ", "").ToLower()
    $domainsToBlock = @(
        "activate.$clean.com",
        "activation.$clean.com",
        "license.$clean.com",
        "lm.licenses.$clean.com",
        "telemetry.$clean.com",
        "updates.$clean.com",
        "mc.$clean.com"
    )

    Write-Host "`nAdding domain entries to Hosts file..." -ForegroundColor Cyan
    
    # Read existing file content safely into array
    $hostsContent = @(Get-Content -Path $HostsPath -ErrorAction SilentlyContinue)
    
    # Create generic list compatible with PowerShell 5.1+
    $newLines = [System.Collections.Generic.List[string]]::new()
    if ($hostsContent.Count -gt 0) { 
        $newLines.AddRange([string[]]$hostsContent) 
    }
    
    $addedCount = 0

    foreach ($dom in $domainsToBlock) {
        $entry = "0.0.0.0 $dom"
        if ($hostsContent -notcontains $entry) {
            $newLines.Add($entry)
            Write-Host "  [+] Added to Hosts: $entry" -ForegroundColor Green
            $addedCount++
        } else {
            Write-Host "  [*] Already in Hosts: $dom" -ForegroundColor DarkGray
        }
    }

    # Write changes if new entries were added using shared stream access
    if ($addedCount -gt 0) {
        try {
            $stream = [System.IO.FileStream]::new($HostsPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
            $writer = [System.IO.StreamWriter]::new($stream, [System.Text.Encoding]::UTF8)
            foreach ($line in $newLines) {
                $writer.WriteLine($line)
            }
            $writer.Dispose()
            $stream.Dispose()
        }
        catch {
            Write-Host "`n[ERROR] Failed to write to hosts file: $_" -ForegroundColor Red
            Write-Host "Your Antivirus/EDR is actively enforcing an exclusive lock on the hosts file." -ForegroundColor Yellow
            return
        }
    }

    Clear-DnsClientCache
    Write-Host "`n[SUCCESS] DNS Cache Flushed." -ForegroundColor Green
}

function Unblock-Target {
    param([string]$SearchTerm)
    
    $cleanTerm = $SearchTerm.Trim('"').Trim("'").Trim()
    if ([string]::IsNullOrWhiteSpace($cleanTerm)) { return }

    Write-Host "`n[1/2] Searching & Removing Windows Firewall Rules matching '$cleanTerm'..." -ForegroundColor Cyan
    
    $allRules = Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "Block_*" }
    $removedCount = 0

    foreach ($rule in $allRules) {
        $filter = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $rule -ErrorAction SilentlyContinue
        $programPath = $filter.Program
        
        if ($rule.DisplayName -like "*$cleanTerm*" -or ($programPath -and $programPath -like "*$cleanTerm*")) {
            Remove-NetFirewallRule -Name $rule.Name -ErrorAction SilentlyContinue
            Write-Host "  [-] Removed Rule: $($rule.DisplayName)" -ForegroundColor Yellow
            $removedCount++
        }
    }

    if ($removedCount -eq 0) {
        Write-Host "  [*] No matching Firewall rules found." -ForegroundColor DarkGray
    } else {
        Write-Host "  [SUCCESS] Removed $removedCount firewall rule(s)." -ForegroundColor Green
    }

    Write-Host "`n[2/2] Cleaning Hosts file entries matching '$cleanTerm'..." -ForegroundColor Cyan
    Set-ItemProperty -Path $HostsPath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
    
    if (Test-Path $HostsPath) {
        $lines = @(Get-Content $HostsPath -ErrorAction SilentlyContinue)
        $filteredLines = $lines | Where-Object { $_ -notmatch [regex]::Escape($cleanTerm) }
        $removedLinesCount = $lines.Count - $filteredLines.Count
        
        if ($removedLinesCount -gt 0) {
            try {
                $stream = [System.IO.FileStream]::new($HostsPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
                $writer = [System.IO.StreamWriter]::new($stream, [System.Text.Encoding]::UTF8)
                foreach ($line in $filteredLines) {
                    $writer.WriteLine($line)
                }
                $writer.Dispose()
                $stream.Dispose()
                
                Write-Host "  [-] Removed $removedLinesCount line(s) from Hosts file." -ForegroundColor Green
                Clear-DnsClientCache
                Write-Host "  [SUCCESS] DNS Cache Flushed." -ForegroundColor Green
            }
            catch {
                Write-Host "  [ERROR] Failed to update Hosts file: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "  [*] No matching domain entries found in Hosts file." -ForegroundColor DarkGray
        }
    }
}

function View-BlockedItems {
    Write-Host "`n====================================================================" -ForegroundColor Cyan
    Write-Host "                  ACTIVE FIREWALL BLOCK RULES                       " -ForegroundColor White
    Write-Host "====================================================================" -ForegroundColor Cyan

    $customRules = Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "Block_*" }

    if ($customRules) {
        foreach ($rule in $customRules) {
            $filter = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $rule -ErrorAction SilentlyContinue
            $direction = $rule.Direction
            $program = if ($filter.Program) { $filter.Program } else { "All Programs" }
            Write-Host " [$direction] $($rule.DisplayName)" -ForegroundColor Green
            Write-Host "    Path: $program" -ForegroundColor Gray
        }
        Write-Host "`n Total custom firewall rules: $($customRules.Count)" -ForegroundColor Yellow
    } else {
        Write-Host " No custom firewall block rules found." -ForegroundColor DarkGray
    }

    Write-Host "`n====================================================================" -ForegroundColor Cyan
    Write-Host "                    BLOCKED HOSTS FILE DOMAINS                      " -ForegroundColor White
    Write-Host "====================================================================" -ForegroundColor Cyan

    if (Test-Path $HostsPath) {
        $hostsLines = Get-Content $HostsPath | Where-Object { $_ -match "^0\.0\.0\.0" }
        if ($hostsLines) {
            foreach ($line in $hostsLines) {
                Write-Host "  $line" -ForegroundColor Green
            }
            Write-Host "`n Total blocked domains: $($hostsLines.Count)" -ForegroundColor Yellow
        } else {
            Write-Host " No custom 0.0.0.0 entries found in Hosts file." -ForegroundColor DarkGray
        }
    }
}

# Interactive Menu Loop
do {
    Clear-Host
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "             POWERSHELL MULTI-DRIVE FIREWALL & HOSTS BLOCKER        " -ForegroundColor White
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "  1. Auto-Search & Block across ALL Drives (C:\, D:\, E:\, etc.)"
    Write-Host "  2. Manually Enter Specific Folder / Drive Path (e.g. D:\, D:\Software)"
    Write-Host "  3. Block Domain Patterns in Hosts File"
    Write-Host "  4. Block BOTH (Auto-Search All Drives + Hosts File Domains)"
    Write-Host "  5. Unblock Software / Folder / Drive Path (Remove Rules & Clean Hosts)"
    Write-Host "  6. View All Blocked Executables & Hosts Entries"
    Write-Host "  7. Exit"
    Write-Host "====================================================================" -ForegroundColor Cyan
    
    $choice = Read-Host "Select an option (1-7)"

    switch ($choice) {
        '1' {
            $name = Read-Host "`nEnter Software / Vendor Name to search (e.g. Adobe, Corel, Autodesk)"
            AutoSearch-And-Block -SoftwareName $name
            Pause
        }
        '2' {
            $folder = Read-Host "`nEnter or paste exact drive or folder path (e.g. D:\ or D:\Games\SoftwareName)"
            Block-ManualFolder -Path $folder
            Pause
        }
        '3' {
            $vendor = Read-Host "`nEnter software/vendor domain name (e.g. adobe, corel)"
            Block-Domains -VendorDomain $vendor
            Pause
        }
        '4' {
            $name = Read-Host "`nEnter Software / Vendor Name (e.g. Adobe, Corel, Autodesk)"
            AutoSearch-And-Block -SoftwareName $name
            Block-Domains -VendorDomain $name
            Pause
        }
        '5' {
            $term = Read-Host "`nEnter software name, executable name, or path to unblock"
            Unblock-Target -SearchTerm $term
            Pause
        }
        '6' {
            View-BlockedItems
            Pause
        }
        '7' {
            break
        }
    }
} while ($choice -ne '7')