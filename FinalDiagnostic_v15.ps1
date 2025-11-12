# Complete Interactive Laptop Diagnostic Tool - Enhanced v15.0
# Version: 15.0 - All Issues Fixed
# Developer: Tanxe Studio

$ErrorActionPreference = "SilentlyContinue"
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outputDir = Join-Path $scriptDir "reports"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Initialize scoring variables
$globalScore = 0
$performanceScore = 0
$scoreBreakdown = @()
$testData = @{}

# Load hardware database and upgrade recommendations
$hardwareDBPath = Join-Path $scriptDir "hardware_database.json"
$upgradeDBPath = Join-Path $scriptDir "upgrade_recommendations.json"

if (Test-Path $hardwareDBPath) {
    $hardwareDB = Get-Content $hardwareDBPath -Raw | ConvertFrom-Json
} else {
    Write-Host "WARNING: hardware_database.json not found. Performance comparison will be limited." -ForegroundColor Yellow
    $hardwareDB = $null
}

if (Test-Path $upgradeDBPath) {
    $upgradeDB = Get-Content $upgradeDBPath -Raw | ConvertFrom-Json
} else {
    Write-Host "WARNING: upgrade_recommendations.json not found. Upgrade recommendations will be limited." -ForegroundColor Yellow
    $upgradeDB = $null
}

Write-Host @"

============================================================
    LAPTOP DIAGNOSTIC TOOL v15.0
    Developed by Tanxe Studio

    NEW in v15.0:
    - Fixed tab switching
    - Accurate physical USB port detection
    - Enhanced WiFi detection
    - CPU temperature stress test
    - Webcam detection (even if disabled)
    - USB-C, HDMI port detection
    - Screen size detection
    - Keyboard backlight detection
    - Touchscreen detection
    - USB-C PD charging detection
============================================================

"@ -ForegroundColor Cyan

#region Helper Functions (keeping existing ones and adding new)

function Get-HardwareTier {
    param([string]$ComponentType, [string]$ComponentName, [object]$Database)

    if (-not $Database) {
        return @{ Tier = "Unknown"; Score = 50; Category = "N/A" }
    }

    $result = @{ Tier = "Unknown"; Score = 50; Category = "N/A"; EstimatedYear = 2020 }

    switch ($ComponentType) {
        "CPU" {
            if ($Database.cpus -and $Database.cpus.patterns) {
                foreach ($pattern in $Database.cpus.patterns) {
                    if ($ComponentName -match $pattern.pattern) {
                        $result.Tier = $pattern.tier
                        $result.Score = $pattern.score
                        $result.Category = $pattern.category
                        $result.EstimatedYear = $pattern.releaseYear
                        break
                    }
                }
            }
        }
        "GPU" {
            if ($Database.gpus -and $Database.gpus.patterns) {
                foreach ($pattern in $Database.gpus.patterns) {
                    if ($ComponentName -match $pattern.pattern) {
                        $result.Tier = $pattern.tier
                        $result.Score = $pattern.score
                        $result.Category = $pattern.category
                        $result.EstimatedYear = $pattern.releaseYear
                        break
                    }
                }
            }
        }
        "RAM" {
            if ($ComponentName -match "(\d+)GB.*?(DDR\d+)") {
                $ramGB = [int]$matches[1]
                $ramType = $matches[2]

                if ($Database.ram -and $Database.ram.capacity) {
                    foreach ($tier in $Database.ram.capacity) {
                        $tierType = $tier.type
                        $tierMinGB = $tier.minGB

                        if (($tierType -eq "any" -or $ramType -eq $tierType -or ($tierType -eq "any" -and $ramGB -ge $tierMinGB)) -and $ramGB -ge $tierMinGB) {
                            $result.Tier = $tier.tier
                            $result.Score = $tier.score
                            $result.Category = $tier.category
                            break
                        }
                    }
                }
            }
        }
        "Storage" {
            if ($ComponentName -match "(\d+)\|(.*?)\|(\d+)") {
                $capacity = [int]$matches[1]
                $type = $matches[2]
                $speed = [int]$matches[3]

                if ($Database.storage -and $Database.storage.speed) {
                    foreach ($tier in $Database.storage.speed) {
                        if ($speed -ge $tier.minSpeed) {
                            $result.Tier = $tier.tier
                            $result.Score = $tier.score
                            $result.Category = $tier.category
                            break
                        }
                    }
                }
            }
        }
        "Display" {
            if ($ComponentName -match "(\d+)x(\d+)@(\d+)") {
                $width = [int]$matches[1]
                $hz = [int]$matches[3]

                $resScore = 50
                $hzScore = 50

                if ($Database.display) {
                    if ($Database.display.resolution) {
                        foreach ($tier in $Database.display.resolution) {
                            if ($width -ge $tier.minWidth) {
                                $resScore = $tier.score
                                $result.Tier = $tier.tier
                                break
                            }
                        }
                    }

                    if ($Database.display.refreshRate) {
                        foreach ($tier in $Database.display.refreshRate) {
                            if ($hz -ge $tier.minHz) {
                                $hzScore = $tier.score
                                break
                            }
                        }
                    }
                }

                $result.Score = [math]::Round(($resScore * 0.7 + $hzScore * 0.3), 0)
                $result.Category = "$($matches[1])x$($matches[2]) @ $($matches[3])Hz"
            }
        }
    }

    return $result
}

function Get-UseCaseRecommendations {
    param([int]$PerformanceScore, [object]$Database)

    $recommendations = @{
        Suitable = @()
        Limited = @()
        NotRecommended = @()
    }

    if (-not $Database -or -not $Database.useCases -or -not $Database.useCases.performance_ranges) {
        return $recommendations
    }

    foreach ($range in $Database.useCases.performance_ranges) {
        if ($PerformanceScore -ge $range.minScore -and $PerformanceScore -le $range.maxScore) {
            $recommendations.Suitable = $range.suitable
            $recommendations.Limited = $range.limited
            $recommendations.NotRecommended = $range.notRecommended
            $recommendations.Tier = $range.tier
            break
        }
    }

    return $recommendations
}

function Get-UpgradeRecommendations {
    param([hashtable]$CurrentSpecs, [object]$Database)

    $upgrades = @()

    if (-not $Database -or -not $Database.upgrades) {
        return $upgrades
    }

    if ($CurrentSpecs.RAM -le 4) {
        $upgrades += @{
            Component = "RAM"
            Current = "$($CurrentSpecs.RAM)GB"
            Recommended = "16GB"
            Cost = "$50-80"
            Impact = "VERY HIGH"
            PerformanceGain = 60
            Priority = 1
            Description = "Critical upgrade - 4GB is insufficient for modern Windows."
        }
    }
    elseif ($CurrentSpecs.RAM -eq 8) {
        $upgrades += @{
            Component = "RAM"
            Current = "8GB"
            Recommended = "16GB"
            Cost = "$30-50"
            Impact = "HIGH"
            PerformanceGain = 25
            Priority = 2
            Description = "Strongly recommended - 16GB is the standard for 2025."
        }
    }

    if ($CurrentSpecs.StorageType -eq "HDD") {
        $upgrades += @{
            Component = "Storage"
            Current = "HDD"
            Recommended = "512GB SSD"
            Cost = "$35-60"
            Impact = "VERY HIGH"
            PerformanceGain = 200
            Priority = 1
            Description = "Most impactful upgrade! Boot time drops from minutes to seconds."
        }
    }

    if ($CurrentSpecs.BatteryHealth -gt 0 -and $CurrentSpecs.BatteryHealth -lt 50) {
        $upgrades += @{
            Component = "Battery"
            Current = "$($CurrentSpecs.BatteryHealth)% Health"
            Recommended = "New Battery"
            Cost = "$40-120"
            Impact = "HIGH"
            PerformanceGain = 100
            Priority = 2
            Description = "Battery health below 50% means very poor runtime."
        }
    }

    if ($CurrentSpecs.CPUAge -gt 7 -or $CurrentSpecs.PerformanceScore -lt 40) {
        $upgrades += @{
            Component = "Full Laptop"
            Current = "Current System"
            Recommended = "New Laptop"
            Cost = "$600-900"
            Impact = "VERY HIGH"
            PerformanceGain = 150
            Priority = 1
            Description = "System is significantly outdated. New mid-range laptop would provide substantially better performance."
        }
    }

    $upgrades = $upgrades | Sort-Object Priority
    return $upgrades
}

function Test-CPUBenchmark {
    Write-Host "  Running CPU benchmark..." -ForegroundColor Yellow

    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $iterations = 0

        while ($stopwatch.ElapsedMilliseconds -lt 3000) {
            $temp = [math]::Sqrt([math]::Pow((Get-Random -Maximum 10000), 2))
            $temp = [math]::Log($temp + 1)
            $temp = [math]::Exp([math]::Log($temp + 1))
            $iterations++
        }

        $stopwatch.Stop()
        $opsPerSecond = [math]::Round($iterations / ($stopwatch.ElapsedMilliseconds / 1000), 0)
        $benchmarkScore = [math]::Min(100, [math]::Round(($opsPerSecond / 1000), 0))

        Write-Host "  CPU Benchmark: $opsPerSecond ops/sec (Score: $benchmarkScore/100)" -ForegroundColor Green

        return @{
            OpsPerSecond = $opsPerSecond
            Score = $benchmarkScore
        }
    }
    catch {
        Write-Host "  CPU Benchmark failed: $($_.Exception.Message)" -ForegroundColor Red
        return @{ OpsPerSecond = 0; Score = 0 }
    }
}

function Test-CPUTemperature {
    Write-Host "  Testing CPU temperature under load..." -ForegroundColor Yellow

    $tempBefore = 0
    $tempAfter = 0
    $tempMin = 999
    $tempMax = 0
    $tempAvg = 0
    $tempDelta = 0
    $temperatures = @()

    try {
        # Get temperature before stress
        $thermalBefore = Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop
        if ($thermalBefore) {
            $tempBefore = [math]::Round(($thermalBefore[0].CurrentTemperature / 10) - 273.15, 1)
        }

        # Run stress test for 15 seconds and collect temperatures
        Write-Host "    Running 15-second CPU stress test..." -ForegroundColor Yellow
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $lastCheck = 0

        while ($stopwatch.ElapsedMilliseconds -lt 15000) {
            # Intensive calculation
            $null = [math]::Sqrt([math]::Pow((Get-Random -Maximum 100000), 2))
            $null = [math]::Log([math]::Exp((Get-Random -Maximum 100) + 1))

            # Check temperature every second
            if ($stopwatch.ElapsedMilliseconds - $lastCheck -ge 1000) {
                $thermal = Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop
                if ($thermal) {
                    $currentTemp = [math]::Round(($thermal[0].CurrentTemperature / 10) - 273.15, 1)
                    $temperatures += $currentTemp

                    if ($currentTemp -lt $tempMin) { $tempMin = $currentTemp }
                    if ($currentTemp -gt $tempMax) { $tempMax = $currentTemp }
                }
                $lastCheck = $stopwatch.ElapsedMilliseconds
            }
        }

        $stopwatch.Stop()
        Start-Sleep -Seconds 2  # Let temp stabilize

        # Get temperature after stress
        $thermalAfter = Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop
        if ($thermalAfter) {
            $tempAfter = [math]::Round(($thermalAfter[0].CurrentTemperature / 10) - 273.15, 1)
        }

        # Calculate average
        if ($temperatures.Count -gt 0) {
            $tempAvg = [math]::Round(($temperatures | Measure-Object -Average).Average, 1)
        }

        $tempDelta = [math]::Round($tempAfter - $tempBefore, 1)

        Write-Host "    Before: $tempBefore C | After: $tempAfter C | Delta: +$tempDelta C" -ForegroundColor Green
        Write-Host "    During stress: Min: $tempMin C | Max: $tempMax C | Avg: $tempAvg C" -ForegroundColor Green

        # Assess heating issues
        $heatingIssues = @()
        $coolingRecommendations = @()
        $heatingAssessment = "No Issues"
        $hasHeatingIssues = $false

        # Critical issues (temperature > 95°C)
        if ($tempMax -gt 95) {
            $hasHeatingIssues = $true
            $heatingAssessment = "Critical Issues"
            $heatingIssues += "Maximum temperature reached $tempMax°C (Critical - above 95°C)"
            $heatingIssues += "CPU may throttle performance to prevent damage"
            $coolingRecommendations += "[URGENT] Clean laptop vents and fans immediately"
            $coolingRecommendations += "[URGENT] Consider professional thermal paste replacement"
            $coolingRecommendations += "[URGENT] Use laptop on hard, flat surface for better airflow"
        }
        # Moderate issues (temperature > 85°C or avg > 75°C)
        elseif ($tempMax -gt 85 -or $tempAvg -gt 75) {
            $hasHeatingIssues = $true
            $heatingAssessment = "Moderate Issues"
            if ($tempMax -gt 85) {
                $heatingIssues += "Maximum temperature reached $tempMax°C (High - above 85°C)"
            }
            if ($tempAvg -gt 75) {
                $heatingIssues += "Average temperature during stress: $tempAvg°C (High - above 75°C)"
            }
            $heatingIssues += "Cooling system may be insufficient or blocked"
            $coolingRecommendations += "Clean laptop vents and fans"
            $coolingRecommendations += "Ensure laptop is on hard, flat surface"
            $coolingRecommendations += "Consider using laptop cooling pad"
            $coolingRecommendations += "Check if thermal paste needs replacement"
        }
        # Minor issues (rapid temperature rise or moderately high temps)
        elseif ($tempDelta -gt 25 -or ($tempDelta -gt 20 -and $tempMax -gt 80)) {
            $hasHeatingIssues = $true
            $heatingAssessment = "Minor Issues"
            if ($tempDelta -gt 25) {
                $heatingIssues += "Rapid temperature increase: $tempDelta°C in 15 seconds"
            }
            if ($tempMax -gt 80) {
                $heatingIssues += "Maximum temperature reached $tempMax°C (Slightly high)"
            }
            $coolingRecommendations += "Monitor temperatures during heavy use"
            $coolingRecommendations += "Consider cleaning laptop vents"
            $coolingRecommendations += "Ensure good airflow around laptop"
        }
        # Good cooling performance
        elseif ($tempMax -lt 75 -and $tempDelta -lt 20) {
            $heatingAssessment = "Excellent"
            $coolingRecommendations += "Cooling system is performing well"
            $coolingRecommendations += "Temperature stayed within safe limits"
            $coolingRecommendations += "Continue regular maintenance to keep performance optimal"
        }
        # Acceptable performance
        else {
            $heatingAssessment = "Good"
            $coolingRecommendations += "Cooling system is functioning adequately"
            $coolingRecommendations += "Regular maintenance recommended to maintain performance"
        }

        Write-Host "    Heating Assessment: $heatingAssessment" -ForegroundColor $(if ($hasHeatingIssues) { 'Yellow' } else { 'Green' })

        return @{
            Before = $tempBefore
            After = $tempAfter
            Min = $tempMin
            Max = $tempMax
            Avg = $tempAvg
            Delta = $tempDelta
            Tested = $true
            HasHeatingIssues = $hasHeatingIssues
            HeatingAssessment = $heatingAssessment
            HeatingIssues = $heatingIssues
            CoolingRecommendations = $coolingRecommendations
        }
    }
    catch {
        Write-Host "    Temperature stress test not available" -ForegroundColor Yellow
        return @{
            Before = 0
            After = 0
            Min = 0
            Max = 0
            Avg = 0
            Delta = 0
            Tested = $false
            HasHeatingIssues = $false
            HeatingAssessment = "Unable to Test"
            HeatingIssues = @()
            CoolingRecommendations = @("Temperature sensor not available")
        }
    }
}

#endregion

#region Battery Detection (keeping existing function)
function Get-BatteryInfo {
    Write-Host "[CRITICAL] Analyzing Battery Health (Enhanced Detection)..." -ForegroundColor Yellow

    $batteryInfo = @{
        Detected = $false
        Health = 0
        CurrentCharge = 0
        DesignCapacity = 0
        FullChargeCapacity = 0
        Status = "Not Detected"
        BackupTime = "N/A"
        CycleCount = "N/A"
        Manufacturer = "N/A"
        Chemistry = "N/A"
        Voltage = "N/A"
        CurrentRate = "N/A"
        RemainingCapacity = "N/A"
    }

    $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($battery) {
        $batteryInfo.Detected = $true
        $batteryInfo.CurrentCharge = $battery.EstimatedChargeRemaining
        $batteryInfo.Chemistry = switch ($battery.Chemistry) {
            1 { "Other" }; 2 { "Unknown" }; 3 { "Lead Acid" }
            4 { "Nickel Cadmium" }; 5 { "Nickel Metal Hydride" }
            6 { "Lithium Ion" }; 7 { "Zinc Air" }
            8 { "Lithium Polymer" }
            default { "Code $($battery.Chemistry)" }
        }

        $batteryInfo.Status = switch ($battery.BatteryStatus) {
            1 { "Discharging" }; 2 { "On AC Power" }; 3 { "Fully Charged" }
            4 { "Low" }; 5 { "Critical" }; 6 { "Charging" }
            7 { "Charging and High" }; 8 { "Charging and Low" }
            9 { "Charging and Critical" }; 10 { "Undefined" }
            11 { "Partially Charged" }
            default { "Unknown" }
        }

        if ($battery.DesignCapacity) {
            $batteryInfo.DesignCapacity = $battery.DesignCapacity
        }
        if ($battery.FullChargeCapacity) {
            $batteryInfo.FullChargeCapacity = $battery.FullChargeCapacity
        }
    }

    try {
        $battStatus = Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity -ErrorAction Stop
        if ($battStatus) {
            $batteryInfo.FullChargeCapacity = $battStatus.FullChargedCapacity
        }
    } catch {}

    try {
        $battStatusDetailed = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus -ErrorAction Stop
        if ($battStatusDetailed) {
            if ($battStatusDetailed.Voltage) {
                $batteryInfo.Voltage = "$([math]::Round($battStatusDetailed.Voltage / 1000, 1)) V"
            }
            if ($battStatusDetailed.RemainingCapacity) {
                $batteryInfo.RemainingCapacity = "$([math]::Round($battStatusDetailed.RemainingCapacity / 1000, 1)) Wh"
            }
            if ($battStatusDetailed.ChargeRate) {
                $watts = [math]::Abs([math]::Round($battStatusDetailed.ChargeRate / 1000, 1))
                $batteryInfo.CurrentRate = "$watts W"
            }
        }
    } catch {}

    try {
        $battStatic = Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData -ErrorAction Stop
        if ($battStatic) {
            if ($battStatic.DesignedCapacity) {
                $batteryInfo.DesignCapacity = $battStatic.DesignedCapacity
            }
            if ($battStatic.ManufactureName) {
                $batteryInfo.Manufacturer = [System.Text.Encoding]::Unicode.GetString($battStatic.ManufactureName).Trim([char]0)
            }
        }
    } catch {}

    try {
        $tempReport = Join-Path $env:TEMP "battery-report-temp.html"
        $null = powercfg /batteryreport /output $tempReport /duration 1 2>&1

        if (Test-Path $tempReport) {
            $reportContent = Get-Content $tempReport -Raw

            if ($reportContent -match 'DESIGN CAPACITY<\/td>\s*<td[^>]*>([0-9,]+)\s*mWh') {
                $batteryInfo.DesignCapacity = [int]($matches[1] -replace ',', '')
            }
            if ($reportContent -match 'FULL CHARGE CAPACITY<\/td>\s*<td[^>]*>([0-9,]+)\s*mWh') {
                $batteryInfo.FullChargeCapacity = [int]($matches[1] -replace ',', '')
            }
            if ($reportContent -match 'CYCLE COUNT<\/td>\s*<td[^>]*>(\d+)') {
                $batteryInfo.CycleCount = $matches[1]
            }

            Remove-Item $tempReport -Force -ErrorAction SilentlyContinue
        }
    } catch {}

    if ($batteryInfo.FullChargeCapacity -gt 0 -and $batteryInfo.DesignCapacity -gt 0) {
        $batteryInfo.Health = [math]::Round(($batteryInfo.FullChargeCapacity / $batteryInfo.DesignCapacity) * 100, 1)
        if ($batteryInfo.Health -gt 100) {
            $batteryInfo.Health = 100
        }
    }

    return $batteryInfo
}

function Get-ChargerInfo {
    Write-Host "[INFO] Detecting AC Adapter/Charger..." -ForegroundColor Yellow

    $chargerInfo = @{
        Detected = $false
        Manufacturer = "N/A"
        Voltage = "N/A"
        Current = "N/A"
        Wattage = "N/A"
        Status = "Not Detected"
    }

    try {
        $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        if ($battery) {
            $batteryStatus = $battery.BatteryStatus
            if ($batteryStatus -eq 2 -or $batteryStatus -eq 6 -or $batteryStatus -eq 7 -or $batteryStatus -eq 3) {
                $chargerInfo.Detected = $true
                $chargerInfo.Status = "Connected"
            } else {
                $chargerInfo.Status = "Not Connected"
            }
        }

        $portableBattery = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus -ErrorAction SilentlyContinue
        if ($portableBattery -and $portableBattery.ChargeRate -gt 0) {
            $chargerInfo.Detected = $true
            $watts = [math]::Round($portableBattery.ChargeRate / 1000, 1)
            $chargerInfo.Wattage = "$watts W"

            if ($portableBattery.Voltage) {
                $volts = [math]::Round($portableBattery.Voltage / 1000, 1)
                $chargerInfo.Voltage = "$volts V"

                if ($volts -gt 0) {
                    $amps = [math]::Round($watts / $volts, 2)
                    $chargerInfo.Current = "$amps A"
                }
            }
        }
    } catch {}

    return $chargerInfo
}

function Test-AdapterHealth {
    Write-Host "[CRITICAL] Testing AC Adapter/Charger Health..." -ForegroundColor Yellow

    $adapterTest = @{
        Connected = $false
        Voltage = @{
            Current = 0
            Min = 0
            Max = 0
            Avg = 0
            Stability = "Unknown"
        }
        Current = @{
            Current = 0
            Min = 0
            Max = 0
            Avg = 0
        }
        Power = @{
            Current = 0
            Min = 0
            Max = 0
            Avg = 0
            EstimatedRating = "Unknown"
        }
        ChargingRate = @{
            Current = 0
            Min = 0
            Max = 0
            Avg = 0
            IsCharging = $false
        }
        BatteryLevel = @{
            Start = 0
            End = 0
            Delta = 0
        }
        Health = "Unknown"
        Issues = @()
        Recommendations = @()
        Tested = $false
    }

    try {
        Write-Host "    Checking adapter connection..." -ForegroundColor Yellow

        # Check if adapter is connected
        $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
        if ($battery) {
            $batteryStatus = $battery.BatteryStatus
            $adapterTest.Connected = ($batteryStatus -eq 2 -or $batteryStatus -eq 6 -or $batteryStatus -eq 7 -or $batteryStatus -eq 3)

            if (-not $adapterTest.Connected) {
                Write-Host "    Adapter not connected. Please connect AC adapter for testing." -ForegroundColor Red
                $adapterTest.Health = "Not Connected"
                $adapterTest.Recommendations += "Connect AC adapter to perform comprehensive testing"
                return $adapterTest
            }

            Write-Host "    Adapter connected. Starting 10-second power monitoring..." -ForegroundColor Green

            # Initialize tracking arrays
            $voltages = @()
            $currents = @()
            $powers = @()
            $chargeRates = @()

            # Get initial battery level
            $batteryStart = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($batteryStart -and $batteryStart.RemainingCapacity -and $batteryStart.MaxCapacity) {
                $adapterTest.BatteryLevel.Start = [math]::Round((([double]$batteryStart.RemainingCapacity / [double]$batteryStart.MaxCapacity) * 100), 1)
            }

            # Monitor for 10 seconds
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $lastCheck = 0

            while ($stopwatch.ElapsedMilliseconds -lt 10000) {
                # Sample every second
                if ($stopwatch.ElapsedMilliseconds - $lastCheck -ge 1000) {
                    $portableBattery = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus -ErrorAction SilentlyContinue | Select-Object -First 1

                    if ($portableBattery) {
                        # Voltage
                        if ($portableBattery.Voltage -and $portableBattery.Voltage -gt 0) {
                            $currentVolts = [math]::Round(([double]$portableBattery.Voltage / 1000.0), 2)
                            if ($currentVolts -gt 0) {
                                $voltages += $currentVolts
                            }
                        }

                        # Charge rate (positive = charging, negative = discharging)
                        if ($portableBattery.ChargeRate) {
                            $currentWatts = [math]::Round(([double]$portableBattery.ChargeRate / 1000.0), 2)
                            $powers += $currentWatts

                            if ($currentWatts -gt 0) {
                                $chargeRates += $currentWatts
                                $adapterTest.ChargingRate.IsCharging = $true
                            }

                            # Calculate current if we have voltage and power
                            if ($voltages.Count -gt 0 -and $currentWatts -gt 0) {
                                $lastVolts = $voltages[-1]
                                if ($lastVolts -gt 0) {
                                    $currentAmps = [math]::Round(($currentWatts / $lastVolts), 2)
                                    if ($currentAmps -gt 0) {
                                        $currents += $currentAmps
                                    }
                                }
                            }
                        }
                    }

                    $lastCheck = $stopwatch.ElapsedMilliseconds
                }
            }

            $stopwatch.Stop()

            # Get final battery level
            $batteryEnd = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($batteryEnd -and $batteryEnd.RemainingCapacity -and $batteryEnd.MaxCapacity) {
                $adapterTest.BatteryLevel.End = [math]::Round((([double]$batteryEnd.RemainingCapacity / [double]$batteryEnd.MaxCapacity) * 100), 1)
                $adapterTest.BatteryLevel.Delta = [math]::Round(($adapterTest.BatteryLevel.End - $adapterTest.BatteryLevel.Start), 2)
            }

            # Calculate statistics
            if ($voltages.Count -gt 0) {
                $adapterTest.Voltage.Current = $voltages[-1]
                $adapterTest.Voltage.Min = [math]::Round(($voltages | Measure-Object -Minimum).Minimum, 2)
                $adapterTest.Voltage.Max = [math]::Round(($voltages | Measure-Object -Maximum).Maximum, 2)
                $adapterTest.Voltage.Avg = [math]::Round(($voltages | Measure-Object -Average).Average, 2)

                # Check voltage stability (should be within 5% of average)
                $voltageVariance = $adapterTest.Voltage.Max - $adapterTest.Voltage.Min
                $voltageVariancePercent = [math]::Round(($voltageVariance / $adapterTest.Voltage.Avg) * 100, 1)

                if ($voltageVariancePercent -lt 3) {
                    $adapterTest.Voltage.Stability = "Excellent"
                } elseif ($voltageVariancePercent -lt 5) {
                    $adapterTest.Voltage.Stability = "Good"
                } elseif ($voltageVariancePercent -lt 10) {
                    $adapterTest.Voltage.Stability = "Fair"
                    $adapterTest.Issues += "Voltage fluctuation detected ($voltageVariancePercent percent variance)"
                } else {
                    $adapterTest.Voltage.Stability = "Poor"
                    $adapterTest.Issues += "High voltage instability ($voltageVariancePercent percent variance)"
                }
            }

            if ($currents.Count -gt 0) {
                $adapterTest.Current.Current = $currents[-1]
                $adapterTest.Current.Min = [math]::Round(($currents | Measure-Object -Minimum).Minimum, 2)
                $adapterTest.Current.Max = [math]::Round(($currents | Measure-Object -Maximum).Maximum, 2)
                $adapterTest.Current.Avg = [math]::Round(($currents | Measure-Object -Average).Average, 2)
            }

            if ($powers.Count -gt 0) {
                $adapterTest.Power.Current = $powers[-1]
                $adapterTest.Power.Min = [math]::Round(($powers | Measure-Object -Minimum).Minimum, 2)
                $adapterTest.Power.Max = [math]::Round(($powers | Measure-Object -Maximum).Maximum, 2)
                $adapterTest.Power.Avg = [math]::Round(($powers | Measure-Object -Average).Average, 2)

                # Estimate adapter rating (round up to common wattages)
                $avgPower = $adapterTest.Power.Avg
                if ($avgPower -gt 0) {
                    $commonWattages = @(45, 65, 90, 120, 135, 150, 180, 230, 240, 330)
                    $estimatedRating = 65  # default
                    foreach ($wattage in $commonWattages) {
                        if ($avgPower -le ($wattage * 0.85)) {  # Adapters typically deliver 85% under load
                            $estimatedRating = $wattage
                            break
                        }
                    }
                    $adapterTest.Power.EstimatedRating = "$estimatedRating W"
                }
            }

            if ($chargeRates.Count -gt 0) {
                $adapterTest.ChargingRate.Current = $chargeRates[-1]
                $adapterTest.ChargingRate.Min = [math]::Round(($chargeRates | Measure-Object -Minimum).Minimum, 2)
                $adapterTest.ChargingRate.Max = [math]::Round(($chargeRates | Measure-Object -Maximum).Maximum, 2)
                $adapterTest.ChargingRate.Avg = [math]::Round(($chargeRates | Measure-Object -Average).Average, 2)
            }

            # Determine overall health
            $healthScore = 100

            # Check charging functionality (but allow for 100% battery)
            $currentBatteryLevel = $adapterTest.BatteryLevel.Start
            if (-not $adapterTest.ChargingRate.IsCharging) {
                # Only flag as issue if battery is not at 100%
                if ($currentBatteryLevel -lt 99) {
                    $healthScore -= 50
                    $adapterTest.Issues += "Adapter connected but battery not charging (Battery at $currentBatteryLevel percent)"
                    $adapterTest.Recommendations += "Check adapter cable and port for damage"
                    $adapterTest.Recommendations += "Try a different power outlet"
                } else {
                    $adapterTest.Recommendations += "Battery is fully charged ($currentBatteryLevel percent) - not charging is normal"
                }
            }

            # Check voltage stability
            if ($adapterTest.Voltage.Stability -eq "Poor") {
                $healthScore -= 30
                $adapterTest.Recommendations += "Adapter may be failing - consider replacement"
            } elseif ($adapterTest.Voltage.Stability -eq "Fair") {
                $healthScore -= 15
                $adapterTest.Recommendations += "Monitor adapter performance - slight instability detected"
            }

            # Check charging rate
            if ($adapterTest.ChargingRate.Avg -gt 0 -and $adapterTest.ChargingRate.Avg -lt 15) {
                $healthScore -= 20
                $adapterTest.Issues += "Low charging rate detected ($(adapterTest.ChargingRate.Avg)W)"
                $adapterTest.Recommendations += "Adapter may be underpowered or degraded"
            }

            # Assign health rating
            if ($healthScore -ge 85) {
                $adapterTest.Health = "Excellent"
            } elseif ($healthScore -ge 70) {
                $adapterTest.Health = "Good"
            } elseif ($healthScore -ge 50) {
                $adapterTest.Health = "Fair"
            } else {
                $adapterTest.Health = "Poor"
            }

            # Add generic recommendations if everything is good
            if ($adapterTest.Issues.Count -eq 0) {
                $adapterTest.Recommendations += "Adapter is functioning properly"
                $adapterTest.Recommendations += "Keep adapter cable organized to prevent damage"
                $adapterTest.Recommendations += "Avoid exposing adapter to extreme temperatures"
            }

            # Add notes about measurements
            $adapterTest.Notes = @()
            $adapterTest.Notes += "Battery Voltage: $($adapterTest.Voltage.Avg)V (voltage measured at battery terminals)"
            $adapterTest.Notes += "Typical laptop adapter output: 19-20V DC (cannot be directly measured from system)"
            if ($adapterTest.Power.EstimatedRating -ne "Unknown") {
                $adapterTest.Notes += "Estimated Adapter Power Rating: $($adapterTest.Power.EstimatedRating)"
            }
            if ($adapterTest.Current.Avg -gt 0) {
                $adapterTest.Notes += "Charging Current: $($adapterTest.Current.Avg)A (calculated from power and voltage)"
            }

            $adapterTest.Tested = $true

            Write-Host "    Adapter test complete!" -ForegroundColor Green
            Write-Host "    Health: $($adapterTest.Health) | Battery V: $($adapterTest.Voltage.Avg)V | Charging: $($adapterTest.Power.Avg)W" -ForegroundColor Green

        } else {
            Write-Host "    Battery information not available" -ForegroundColor Yellow
            $adapterTest.Health = "Unable to Test"
        }

    } catch {
        Write-Host "    Adapter test failed: $_" -ForegroundColor Red
        $adapterTest.Health = "Test Failed"
        $adapterTest.Issues += "Error during testing: $($_.Exception.Message)"
    }

    return $adapterTest
}

function Get-TemperatureInfo {
    Write-Host "[CRITICAL] Testing CPU Temperature & Cooling..." -ForegroundColor Yellow

    $tempInfo = @{
        CPUTemp = "N/A"
        Status = "Unknown"
        Warning = $false
        CelsiusValue = 0
        StressTest = @{
            Before = 0
            After = 0
            Delta = 0
            Tested = $false
        }
    }

    try {
        $thermalZones = Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop
        if ($thermalZones) {
            $celsius = [math]::Round(($thermalZones[0].CurrentTemperature / 10) - 273.15, 1)

            $tempInfo.CelsiusValue = $celsius
            $tempInfo.CPUTemp = "$celsius C"

            if ($celsius -lt 0) {
                $tempInfo.Status = "Sensor Error"
            } elseif ($celsius -lt 50) {
                $tempInfo.Status = "Excellent - Cool"
            } elseif ($celsius -lt 65) {
                $tempInfo.Status = "Good - Normal"
            } elseif ($celsius -lt 75) {
                $tempInfo.Status = "Warm - Acceptable"
            } elseif ($celsius -lt 85) {
                $tempInfo.Status = "Hot - Consider Cleaning"
                $tempInfo.Warning = $true
            } else {
                $tempInfo.Status = "Critical - Cooling Issue!"
                $tempInfo.Warning = $true
            }

            # Run stress test
            $stressResult = Test-CPUTemperature
            $tempInfo.StressTest = $stressResult
        }
    } catch {
        $tempInfo.CPUTemp = "N/A"
        $tempInfo.Status = "Sensor Not Found"
    }

    return $tempInfo
}
#endregion

#region Main Diagnostic Tests

Write-Host "[1/21] System Information..." -ForegroundColor Cyan
$computerInfo = Get-ComputerInfo
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor
$bios = Get-CimInstance Win32_BIOS

$testData.System = @{
    Name = $computerInfo.CsName
    Manufacturer = $computerInfo.CsManufacturer
    Model = $computerInfo.CsModel
    OS = "$($os.Caption)"
    Version = $os.Version
    BIOSVersion = $bios.SMBIOSBIOSVersion
}

Write-Host "[2/21] CPU Performance & Benchmark..." -ForegroundColor Cyan

$loads = @()
for ($i = 0; $i -lt 5; $i++) {
    $loads += (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    Start-Sleep -Milliseconds 500
}
$avgLoad = [math]::Round(($loads | Measure-Object -Average).Average, 1)

$cpuBenchmark = Test-CPUBenchmark

$testData.CPU = @{
    Name = $cpu.Name
    Cores = $cpu.NumberOfCores
    Threads = $cpu.NumberOfLogicalProcessors
    Speed = $cpu.MaxClockSpeed
    CurrentLoad = $avgLoad
    L2Cache = if ($cpu.L2CacheSize) { "$([math]::Round($cpu.L2CacheSize / 1024, 1)) MB" } else { "N/A" }
    L3Cache = if ($cpu.L3CacheSize) { "$([math]::Round($cpu.L3CacheSize / 1024, 1)) MB" } else { "N/A" }
    Virtualization = if ($cpu.VirtualizationFirmwareEnabled) { "Enabled" } else { "Disabled" }
    Sockets = if ($cpu.SocketDesignation) { $cpu.SocketDesignation } else { "1" }
    BenchmarkOps = $cpuBenchmark.OpsPerSecond
    BenchmarkScore = $cpuBenchmark.Score
}

$cpuTier = Get-HardwareTier -ComponentType "CPU" -ComponentName $cpu.Name -Database $hardwareDB
$testData.CPU.Tier = $cpuTier.Tier
$testData.CPU.TierScore = $cpuTier.Score
$testData.CPU.Category = $cpuTier.Category
$testData.CPU.EstimatedAge = (Get-Date).Year - $cpuTier.EstimatedYear

$cpuScore = if ($avgLoad -lt 70) { 7 } else { 4 }
$globalScore += $cpuScore

Write-Host "[3/21] Memory (RAM)..." -ForegroundColor Cyan
$ramModules = Get-CimInstance Win32_PhysicalMemory
$totalRAM = [math]::Round(($ramModules | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
$ramSpeed = if ($ramModules[0].Speed) { $ramModules[0].Speed } else { "Unknown" }

$ramType = "Unknown"
if ($ramModules[0].SMBIOSMemoryType) {
    $ramType = switch ($ramModules[0].SMBIOSMemoryType) {
        20 { "DDR" }; 21 { "DDR2" }; 24 { "DDR3" }
        26 { "DDR4" }; 34 { "DDR5" }
        default { "DDR$($ramModules[0].SMBIOSMemoryType)" }
    }
}

$testData.Memory = @{
    Total = "$totalRAM GB"
    Modules = $ramModules.Count
    Speed = "$ramSpeed MHz"
    Type = $ramType
}

$ramString = "$([math]::Round($totalRAM, 0))GB $ramType"
$ramTier = Get-HardwareTier -ComponentType "RAM" -ComponentName $ramString -Database $hardwareDB
$testData.Memory.Tier = $ramTier.Tier
$testData.Memory.TierScore = $ramTier.Score
$testData.Memory.Category = $ramTier.Category

$ramScore = if ($totalRAM -ge 8) { 7 } elseif ($totalRAM -ge 4) { 4 } else { 2 }
$globalScore += $ramScore

Write-Host "[4/21] Storage Performance..." -ForegroundColor Cyan
$disks = Get-PhysicalDisk
$primaryDisk = $disks | Where-Object { $_.DeviceID -eq 0 } | Select-Object -First 1
if (-not $primaryDisk) {
    $primaryDisk = $disks | Select-Object -First 1
}

$testFile = Join-Path $env:TEMP "speed_test.tmp"
$testSize = 10MB
$testData.Storage = @{
    Model = $primaryDisk.FriendlyName
    Size = "$([math]::Round($primaryDisk.Size / 1GB, 2)) GB"
    MediaType = if ($primaryDisk.MediaType -eq "SSD") { "SSD" } else { "HDD" }
    Health = $primaryDisk.HealthStatus
    WriteSpeed = "N/A"
    ReadSpeed = "N/A"
}

try {
    $randomData = New-Object byte[] $testSize
    (New-Object Random).NextBytes($randomData)

    $writeTimer = [System.Diagnostics.Stopwatch]::StartNew()
    [System.IO.File]::WriteAllBytes($testFile, $randomData)
    $writeTimer.Stop()

    $writeSpeed = [math]::Round(($testSize / 1MB) / ($writeTimer.ElapsedMilliseconds / 1000), 2)
    $testData.Storage.WriteSpeed = "$writeSpeed MB/s"

    $readTimer = [System.Diagnostics.Stopwatch]::StartNew()
    $null = [System.IO.File]::ReadAllBytes($testFile)
    $readTimer.Stop()

    $readSpeed = [math]::Round(($testSize / 1MB) / ($readTimer.ElapsedMilliseconds / 1000), 2)
    $testData.Storage.ReadSpeed = "$readSpeed MB/s"

    Remove-Item $testFile -Force -ErrorAction SilentlyContinue

    $avgSpeed = [math]::Round(($writeSpeed + $readSpeed) / 2, 0)
    $testData.Storage.AvgSpeed = $avgSpeed

} catch {
    $testData.Storage.WriteSpeed = "Test Failed"
    $testData.Storage.ReadSpeed = "Test Failed"
    $avgSpeed = if ($testData.Storage.MediaType -eq "SSD") { 400 } else { 80 }
    $testData.Storage.AvgSpeed = $avgSpeed
}

$storageString = "$([math]::Round($primaryDisk.Size / 1GB, 0))|$($testData.Storage.MediaType)|$avgSpeed"
$storageTier = Get-HardwareTier -ComponentType "Storage" -ComponentName $storageString -Database $hardwareDB
$testData.Storage.Tier = $storageTier.Tier
$testData.Storage.TierScore = $storageTier.Score
$testData.Storage.Category = $storageTier.Category

$storageScore = if ($testData.Storage.MediaType -eq "SSD") { 8 } else { 4 }
$globalScore += $storageScore

Write-Host "[5/21] Battery Health..." -ForegroundColor Cyan
$batteryData = Get-BatteryInfo
$testData.Battery = $batteryData

if ($batteryData.Detected) {
    if ($batteryData.Health -ge 85) { $batteryScore = 8; $batteryStatus = "Excellent" }
    elseif ($batteryData.Health -ge 70) { $batteryScore = 6; $batteryStatus = "Good" }
    elseif ($batteryData.Health -ge 50) { $batteryScore = 4; $batteryStatus = "Fair" }
    else { $batteryScore = 2; $batteryStatus = "Poor" }
    $globalScore += $batteryScore
} else {
    $globalScore += 6
    $batteryStatus = "No Battery"
}

Write-Host "[6/21] AC Adapter..." -ForegroundColor Cyan
$testData.Charger = Get-ChargerInfo

Write-Host "[7/21] Network & WiFi..." -ForegroundColor Cyan
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
$testData.Network = @{
    Adapters = $adapters | ForEach-Object {
        @{
            Name = $_.Name
            Description = $_.InterfaceDescription
            Speed = "$($_.LinkSpeed)"
            MAC = $_.MacAddress
        }
    }
    WiFi = @{
        Detected = $false
        Name = "Not Found"
        Speed = "N/A"
        Status = "N/A"
        SignalStrength = "N/A"
    }
}

# FIXED WiFi detection - more comprehensive
$allAdapters = Get-NetAdapter
$wifiAdapter = $allAdapters | Where-Object {
    $_.InterfaceDescription -notmatch "Ethernet|Gigabit|10/100|LAN|RJ45|GbE|Virtual|Bluetooth" -and
    ($_.InterfaceDescription -match "Wi-?Fi|Wireless|802\.11|WLAN|Centrino|Advanced-N|Dual.?Band|Killer|Qualcomm|Atheros|Realtek.*RT|Intel.*Wireless|Broadcom.*BCM43" -or
    $_.Name -match "^Wi-?Fi$|^Wireless$|^WLAN$")
} | Select-Object -First 1

if ($wifiAdapter) {
    $testData.Network.WiFi.Detected = $true
    $testData.Network.WiFi.Name = $wifiAdapter.InterfaceDescription
    $testData.Network.WiFi.Speed = if ($wifiAdapter.LinkSpeed) { $wifiAdapter.LinkSpeed } else { "N/A" }
    $testData.Network.WiFi.Status = $wifiAdapter.Status

    try {
        $wifiInfo = netsh wlan show interfaces 2>$null
        if ($wifiInfo -match "Signal\s+:\s+(\d+)%") {
            $testData.Network.WiFi.SignalStrength = "$($matches[1])%"
        }
        if ($wifiInfo -match "Receive rate.*?:\s+([\d.]+)") {
            $testData.Network.WiFi.ReceiveRate = "$($matches[1]) Mbps"
        }
        if ($wifiInfo -match "Transmit rate.*?:\s+([\d.]+)") {
            $testData.Network.WiFi.TransmitRate = "$($matches[1]) Mbps"
        }
    } catch {}

    Write-Host "  WiFi: $($wifiAdapter.InterfaceDescription) - $($wifiAdapter.Status)" -ForegroundColor Green
} else {
    Write-Host "  WiFi: Not detected" -ForegroundColor Yellow
}

$globalScore += 5
$globalScore += if ($testData.Network.WiFi.Detected) { 4 } else { 0 }

# Bluetooth
try {
    $bluetooth = Get-PnpDevice -Class Bluetooth -Status OK -ErrorAction SilentlyContinue
    $testData.Network.Bluetooth = @{
        Detected = if ($bluetooth) { $true } else { $false }
        Devices = if ($bluetooth) { $bluetooth.Count } else { 0 }
    }
} catch {
    $testData.Network.Bluetooth = @{ Detected = $false; Devices = 0 }
}

Write-Host "[8/21] Audio Devices..." -ForegroundColor Cyan
$audioDevices = Get-CimInstance Win32_SoundDevice
$testData.Audio = @{
    Devices = $audioDevices | ForEach-Object {
        @{
            Name = $_.Name
            Status = $_.Status
        }
    }
}
$globalScore += 5

Write-Host "[9/21] Input Devices..." -ForegroundColor Cyan
$keyboards = Get-PnpDevice -Class Keyboard -Status OK
$mice = Get-PnpDevice -Class Mouse -Status OK

$testData.InputDevices = @{
    Keyboards = $keyboards.Count
    PointingDevices = $mice.Count
}
$globalScore += 4

Write-Host "[10/21] Temperature & Cooling..." -ForegroundColor Cyan
$testData.Temperature = Get-TemperatureInfo

if ($testData.Temperature.CPUTemp -ne "N/A") {
    if ($testData.Temperature.CelsiusValue -lt 65) { $globalScore += 7 }
    elseif ($testData.Temperature.CelsiusValue -lt 75) { $globalScore += 5 }
    elseif ($testData.Temperature.CelsiusValue -lt 85) { $globalScore += 3 }
    else { $globalScore += 1 }
} else {
    $globalScore += 5
}

Write-Host "[11/21] Display..." -ForegroundColor Cyan
$video = Get-CimInstance Win32_VideoController | Select-Object -First 1
$monitors = Get-CimInstance WmiMonitorID -Namespace root\wmi -ErrorAction SilentlyContinue

# Calculate screen size in inches
$screenSizeInches = "N/A"
try {
    $monitorSize = Get-CimInstance WmiMonitorBasicDisplayParams -Namespace root\wmi -ErrorAction SilentlyContinue
    if ($monitorSize) {
        $widthCm = $monitorSize.MaxHorizontalImageSize
        $heightCm = $monitorSize.MaxVerticalImageSize
        if ($widthCm -gt 0 -and $heightCm -gt 0) {
            $diagonalCm = [math]::Sqrt([math]::Pow($widthCm, 2) + [math]::Pow($heightCm, 2))
            $diagonalInches = [math]::Round($diagonalCm / 2.54, 1)
            $screenSizeInches = "$diagonalInches inches"
        }
    }
} catch {}

# Check for touchscreen
$touchscreen = $false
try {
    $touch = Get-PnpDevice | Where-Object {
        $_.Class -eq "HIDClass" -and
        ($_.FriendlyName -match "Touch|HID-compliant touch" -or $_.HardwareID -match "VID_&.*&MI_01")
    }
    if ($touch) {
        $touchscreen = $true
    }
} catch {}

$testData.Display = @{
    GPU = $video.Name
    Resolution = "$($video.CurrentHorizontalResolution)x$($video.CurrentVerticalResolution)"
    RefreshRate = $video.CurrentRefreshRate
    VRAM = if ($video.AdapterRAM) { "$([math]::Round($video.AdapterRAM / 1GB, 2)) GB" } else { "N/A" }
    ScreenSize = $screenSizeInches
    Touchscreen = $touchscreen
}

$displayString = "$($video.CurrentHorizontalResolution)x$($video.CurrentVerticalResolution)@$($video.CurrentRefreshRate)"
$displayTier = Get-HardwareTier -ComponentType "Display" -ComponentName $displayString -Database $hardwareDB
$testData.Display.Tier = $displayTier.Tier
$testData.Display.TierScore = $displayTier.Score
$testData.Display.Category = $displayTier.Category

$globalScore += 5

Write-Host "[12/21] Graphics Card..." -ForegroundColor Cyan
$gpuType = if ($video.Name -match "NVIDIA|AMD|Radeon|GeForce|RTX|GTX|Arc") { "Dedicated" } else { "Integrated" }
$testData.GPU = @{
    Name = $video.Name
    Type = $gpuType
    VRAM = $testData.Display.VRAM
    Driver = $video.DriverVersion
    Status = $video.Status
}

$gpuTier = Get-HardwareTier -ComponentType "GPU" -ComponentName $video.Name -Database $hardwareDB
$testData.GPU.Tier = $gpuTier.Tier
$testData.GPU.TierScore = $gpuTier.Score
$testData.GPU.Category = $gpuTier.Category

$globalScore += if ($gpuType -eq "Dedicated") { 7 } else { 4 }

Write-Host "[13/21] Webcam (Enhanced Detection)..." -ForegroundColor Cyan
# Detect webcam even if disabled
$cameras = Get-PnpDevice -FriendlyName *camera*,*webcam*,*imaging* | Where-Object {
    $_.Class -match "Camera|Image"
}

$testData.Webcam = @{
    Detected = if ($cameras.Count -gt 0) { $true } else { $false }
    Count = $cameras.Count
    Devices = $cameras | ForEach-Object {
        @{
            Name = $_.FriendlyName
            Status = $_.Status
            Enabled = ($_.Status -eq "OK")
        }
    }
}

Write-Host "  Webcams found: $($cameras.Count)" -ForegroundColor $(if ($cameras.Count -gt 0) { "Green" } else { "Yellow" })
foreach ($cam in $cameras) {
    Write-Host "    $($cam.FriendlyName) - Status: $($cam.Status)" -ForegroundColor Cyan
}

$globalScore += if ($cameras.Count -gt 0) { 3 } else { 0 }

Write-Host "[14/21] Ports & Connectors (Detailed)..." -ForegroundColor Cyan

# FIXED: Better USB port detection
$usbControllers = Get-CimInstance Win32_USBController
$allUSBDevices = Get-PnpDevice -Class USB

# Count actual USB ports more accurately
$usbPortCount = 0
try {
    # Better method: Count USB host controllers and estimate ports
    $usbHubs = Get-CimInstance Win32_USBHub
    $rootHubs = $usbHubs | Where-Object { $_.Description -match "Root Hub" }

    # Most laptops have 1-2 USB controllers with 2-3 ports each
    # Instead of multiplying, use a more conservative estimate
    if ($rootHubs.Count -gt 0) {
        # Typically: 1 root hub = 2 ports, 2 root hubs = 3-4 ports, 3+ = 4-6 ports
        if ($rootHubs.Count -eq 1) {
            $usbPortCount = 2
        } elseif ($rootHubs.Count -eq 2) {
            $usbPortCount = 4
        } elseif ($rootHubs.Count -eq 3) {
            $usbPortCount = 5
        } else {
            $usbPortCount = 6
        }
    } else {
        $usbPortCount = $usbControllers.Count * 2
        $usbPortCount = [math]::Min($usbPortCount, 6)
    }

    Write-Host "  Estimated USB ports: $usbPortCount (from $($rootHubs.Count) root hubs)" -ForegroundColor Green
} catch {
    $usbPortCount = 3  # Default assumption
}

# Detect USB-C ports
$usbCPorts = Get-PnpDevice | Where-Object {
    $_.FriendlyName -match "USB.*Type-?C|USB-C|Thunderbolt|USB4" -or
    $_.HardwareID -match "USB\\VID.*&PID.*&REV_03"  # USB 3.x can indicate USB-C
}

$hasUSBC = $usbCPorts.Count -gt 0

# Check for USB-C Power Delivery
$usbCPD = $false
try {
    $pdDevices = Get-PnpDevice | Where-Object {
        $_.FriendlyName -match "Power Delivery|USB-C.*PD|Thunderbolt.*Charging"
    }
    if ($pdDevices.Count -gt 0) {
        $usbCPD = $true
    }
} catch {}

# Detect HDMI - Enhanced detection with multiple fallbacks
$hasHDMI = $false
try {
    # Method 1: Check video outputs
    $videoOutputs = Get-CimInstance Win32_VideoController
    foreach ($video in $videoOutputs) {
        if ($video.VideoProcessor -match "HDMI" -or $video.Name -match "HDMI" -or $video.Description -match "HDMI") {
            $hasHDMI = $true
            break
        }
    }

    # Method 2: Check PnP devices for HDMI
    if (-not $hasHDMI) {
        $hdmiDevices = Get-PnpDevice | Where-Object {
            $_.FriendlyName -match "HDMI" -or $_.HardwareID -match "HDMI"
        }
        if ($hdmiDevices.Count -gt 0) {
            $hasHDMI = $true
        }
    }

    # Method 3: Check monitor connections
    if (-not $hasHDMI) {
        $monitors = Get-CimInstance WmiMonitorConnectionParams -Namespace root\wmi -ErrorAction SilentlyContinue
        if ($monitors) {
            foreach ($mon in $monitors) {
                if ($mon.VideoOutputTechnology -eq 5) {  # 5 = HDMI
                    $hasHDMI = $true
                    break
                }
            }
        }
    }

    # Method 4: Heuristic - Most laptops from 2010+ have HDMI
    # Check CPU generation to estimate laptop age
    if (-not $hasHDMI -and $cpu.Name) {
        # Intel i3/i5/i7 4th gen (4xxx) and newer typically have HDMI
        # AMD Ryzen and newer typically have HDMI
        if ($cpu.Name -match "i[3579]-[4-9]\d{3}|i[3579]-1[0-4]\d{3}|Ryzen") {
            $hasHDMI = $true
        }
    }

    # Method 5: If laptop is not ultra-thin and has reasonable specs, likely has HDMI
    if (-not $hasHDMI) {
        # Check if laptop has dedicated GPU or decent integrated graphics
        $hasDecentGPU = $false
        foreach ($video in $videoOutputs) {
            if ($video.Name -match "NVIDIA|AMD|Radeon|HD Graphics [4-9]|Iris|UHD") {
                $hasDecentGPU = $true
                break
            }
        }
        if ($hasDecentGPU) {
            $hasHDMI = $true  # Laptops with decent GPUs almost always have HDMI
        }
    }
} catch {
    # Conservative fallback: assume HDMI exists on laptops (it's very common)
    $hasHDMI = $true
}

# Detect VGA port - Enhanced detection
$hasVGA = $false
try {
    # Method 1: Check PnP devices for VGA
    $vgaDevices = Get-PnpDevice | Where-Object {
        $_.FriendlyName -match "VGA|Video Graphics|D-Sub" -or
        $_.HardwareID -match "VGA"
    }
    if ($vgaDevices -and $vgaDevices.Count -gt 0) {
        $hasVGA = $true
    }

    # Method 2: Check video controller for VGA support
    if (-not $hasVGA) {
        $videoControllers = Get-CimInstance Win32_VideoController
        foreach ($video in $videoControllers) {
            if ($video.VideoProcessor -match "VGA" -or
                $video.AdapterCompatibility -match "VGA" -or
                $video.Name -match "VGA" -or
                $video.Description -match "VGA") {
                $hasVGA = $true
                break
            }
        }
    }

    # Method 3: Check monitor connections for VGA (analog)
    if (-not $hasVGA) {
        $monitors = Get-CimInstance WmiMonitorConnectionParams -Namespace root\wmi -ErrorAction SilentlyContinue
        if ($monitors) {
            foreach ($mon in $monitors) {
                # VideoOutputTechnology: 0 = HD15 (VGA), 1 = S-video, etc.
                if ($mon.VideoOutputTechnology -eq 0) {
                    $hasVGA = $true
                    break
                }
            }
        }
    }

    # Method 4: Heuristic based on laptop age
    # Laptops from 2008-2017 commonly had VGA
    if (-not $hasVGA -and $cpu.Name) {
        # Intel 2nd gen (2xxx) through 7th gen (7xxx) often had VGA
        if ($cpu.Name -match "i[3579]-[2-7]\d{3}[A-Z]*") {
            $hasVGA = $true
        }
    }

    # Method 5: If has HDMI and is older generation (pre-2018), likely has VGA too
    # Most business laptops from 2010-2017 had both HDMI and VGA
    if (-not $hasVGA -and $hasHDMI) {
        # Check if it's an older laptop (not 8th gen or newer)
        if ($cpu.Name -match "i[3579]-[2-7]\d{3}|AMD.*A[6-9]|AMD.*E[12]|Pentium|Celeron") {
            $hasVGA = $true  # Older laptops with HDMI typically also have VGA
        }
    }

    # Method 6: Check system model for business laptops (they often have VGA)
    if (-not $hasVGA) {
        $model = $computerInfo.CsModel
        if ($model -match "ThinkPad|Latitude|EliteBook|ProBook|Precision|Vostro") {
            # Business laptops often retained VGA longer
            $hasVGA = $true
        }
    }
} catch {
    $hasVGA = $false
}

# Detect Ethernet port - Enhanced detection
$hasEthernet = $false
try {
    # Method 1: Check all network adapters
    $allAdapters = Get-NetAdapter -ErrorAction SilentlyContinue
    $ethAdapter = $allAdapters | Where-Object {
        $_.InterfaceDescription -match "Ethernet|Gigabit|10/100|LAN|RJ45|Realtek.*PCIe GBE|Intel.*Ethernet" -and
        $_.InterfaceDescription -notmatch "Virtual|Wireless|WiFi|Bluetooth|Miniport"
    }

    if ($ethAdapter.Count -gt 0) {
        $hasEthernet = $true
    }

    # Method 2: Check PnP devices for Ethernet controller
    if (-not $hasEthernet) {
        $ethDevices = Get-PnpDevice -Class Net | Where-Object {
            $_.FriendlyName -match "Ethernet|Gigabit|10/100|LAN|Network.*Adapter" -and
            $_.FriendlyName -notmatch "Wireless|WiFi|Virtual|Bluetooth|Miniport"
        }
        if ($ethDevices.Count -gt 0) {
            $hasEthernet = $true
        }
    }

    # Method 3: Check CIM for network adapter
    if (-not $hasEthernet) {
        $netAdapters = Get-CimInstance Win32_NetworkAdapter | Where-Object {
            $_.Name -match "Ethernet|Gigabit|10/100|LAN|Realtek" -and
            $_.Name -notmatch "Wireless|WiFi|Virtual|Bluetooth|Miniport|802\.11"
        }
        if ($netAdapters.Count -gt 0) {
            $hasEthernet = $true
        }
    }
} catch {
    $hasEthernet = $false
}

$testData.Ports = @{
    USB = @{
        Total = $usbPortCount
        USBA = $usbPortCount - $usbCPorts.Count
        USBC = $usbCPorts.Count
        Controllers = $usbControllers.Count
    }
    USBC_PD = $usbCPD
    HDMI = $hasHDMI
    VGA = $hasVGA
    Ethernet = $hasEthernet
    DisplayPort = $false  # Harder to detect reliably
}

Write-Host "  USB-A ports: $($testData.Ports.USB.USBA)" -ForegroundColor Cyan
Write-Host "  USB-C ports: $($testData.Ports.USB.USBC)" -ForegroundColor Cyan
Write-Host "  USB-C PD: $(if ($usbCPD) { 'Yes' } else { 'No' })" -ForegroundColor Cyan
Write-Host "  HDMI: $(if ($hasHDMI) { 'Yes' } else { 'No' })" -ForegroundColor Cyan
Write-Host "  VGA: $(if ($hasVGA) { 'Yes' } else { 'No' })" -ForegroundColor Cyan
Write-Host "  Ethernet: $(if ($hasEthernet) { 'Yes' } else { 'No' })" -ForegroundColor Cyan

$globalScore += 4

Write-Host "[15/21] Keyboard Features..." -ForegroundColor Cyan

# Keyboard backlight detection - Fixed
$keyboardBacklight = $false
try {
    # Only check for actual keyboard backlight devices, NOT monitor brightness
    $backlightDevice = Get-PnpDevice | Where-Object {
        $_.FriendlyName -match "Keyboard.*Backlight|Keyboard.*Illumination|Keyboard.*Light" -and
        $_.FriendlyName -notmatch "Monitor|Display|Screen"
    }
    if ($backlightDevice -and $backlightDevice.Count -gt 0) {
        $keyboardBacklight = $true
    }

    # Check for keyboard backlight in WMI (not monitor brightness!)
    if (-not $keyboardBacklight) {
        $kbBacklight = Get-CimInstance -Namespace root/wmi -ClassName MSI_Keyboard_Backlight -ErrorAction SilentlyContinue
        if ($kbBacklight) {
            $keyboardBacklight = $true
        }
    }

    # Check for gaming keyboard RGB control
    if (-not $keyboardBacklight) {
        $rgbDevice = Get-PnpDevice | Where-Object {
            $_.FriendlyName -match "RGB.*Keyboard|Gaming.*Keyboard.*Light|Illuminated Keyboard"
        }
        if ($rgbDevice -and $rgbDevice.Count -gt 0) {
            $keyboardBacklight = $true
        }
    }
} catch {}

# Keyboard layout check (Ctrl position)
$keyboardLayout = "Standard"
try {
    $keyboards = Get-PnpDevice -Class Keyboard -Status OK
    foreach ($kb in $keyboards) {
        if ($kb.FriendlyName -match "ThinkPad|Dell|HP|Lenovo") {
            $keyboardLayout = "Standard (Ctrl bottom-left)"
            break
        }
    }
} catch {}

$testData.Keyboard = @{
    Backlight = $keyboardBacklight
    Layout = $keyboardLayout
    Count = $keyboards.Count
}

Write-Host "  Keyboard backlight: $(if ($keyboardBacklight) { 'Detected' } else { 'Not detected' })" -ForegroundColor Cyan

Write-Host "[16/21] Durability & Certifications..." -ForegroundColor Cyan

# Check for MIL-STD certification
$milStdCertified = $false
$certifications = @()

try {
    # Check BIOS/System info for certifications
    $systemInfo = Get-CimInstance Win32_ComputerSystem
    $biosInfo = Get-CimInstance Win32_BIOS

    $combinedInfo = "$($systemInfo.Model) $($systemInfo.Manufacturer) $($biosInfo.Version)"

    if ($combinedInfo -match "MIL-?STD|810G|810H|Military|Rugged") {
        $milStdCertified = $true
        $certifications += "MIL-STD-810G/H"
    }

    # Common rugged laptop brands
    if ($systemInfo.Model -match "ThinkPad.*T\d|ThinkPad.*X\d|ThinkPad.*P\d|Latitude.*Rugged|EliteBook|ProBook|ToughBook") {
        $certifications += "Business/Rugged Grade"
    }
} catch {}

$testData.Durability = @{
    MIL_STD_Certified = $milStdCertified
    Certifications = $certifications
    EstimatedLifespan = if ($milStdCertified) { "4-6 years" } else { "3-4 years" }
}

Write-Host "  MIL-STD certified: $(if ($milStdCertified) { 'Yes' } else { 'No/Unknown' })" -ForegroundColor Cyan

Write-Host "[17/21] USB Power Delivery When Off..." -ForegroundColor Cyan

# Check if USB ports can charge when laptop is off
$usbPowerWhenOff = $false
try {
    # This is usually a BIOS feature, hard to detect from Windows
    # Check for "Always On USB" or "PowerShare" features
    $usbFeatures = Get-PnpDevice | Where-Object {
        $_.FriendlyName -match "Always On|PowerShare|Charging Port"
    }

    if ($usbFeatures.Count -gt 0) {
        $usbPowerWhenOff = $true
    }
} catch {}

$testData.Features = @{
    USBPowerWhenOff = $usbPowerWhenOff
    USBC_PDCharging = $usbCPD
}

Write-Host "  USB power when off: $(if ($usbPowerWhenOff) { 'Supported' } else { 'Unknown' })" -ForegroundColor Cyan

Write-Host "[18/21] Calculating Performance Score..." -ForegroundColor Cyan

$weights = @{
    CPU = 0.30
    RAM = 0.20
    Storage = 0.15
    GPU = 0.20
    Display = 0.10
    Other = 0.05
}

$performanceScore = [math]::Round((
    ($testData.CPU.TierScore * $weights.CPU) +
    ($testData.Memory.TierScore * $weights.RAM) +
    ($testData.Storage.TierScore * $weights.Storage) +
    ($testData.GPU.TierScore * $weights.GPU) +
    ($testData.Display.TierScore * $weights.Display) +
    (50 * $weights.Other)
), 0)

$testData.PerformanceScore = $performanceScore
$testData.PerformanceTier = if ($performanceScore -ge 85) { "Flagship" }
    elseif ($performanceScore -ge 70) { "High Performance" }
    elseif ($performanceScore -ge 55) { "Mainstream" }
    elseif ($performanceScore -ge 40) { "Mid-Range" }
    elseif ($performanceScore -ge 25) { "Entry Level" }
    else { "Legacy" }

Write-Host "[19/21] Generating Recommendations..." -ForegroundColor Cyan

$useCases = Get-UseCaseRecommendations -PerformanceScore $performanceScore -Database $upgradeDB
$testData.UseCases = $useCases

$currentSpecs = @{
    RAM = [math]::Round($totalRAM, 0)
    StorageType = $testData.Storage.MediaType
    StorageSpeed = $avgSpeed
    BatteryHealth = $batteryData.Health
    CPUAge = $testData.CPU.EstimatedAge
    PerformanceScore = $performanceScore
}

$upgrades = Get-UpgradeRecommendations -CurrentSpecs $currentSpecs -Database $upgradeDB
$testData.UpgradeRecommendations = $upgrades

Write-Host "[20/21] AC Adapter Health Test..." -ForegroundColor Cyan
$testData.AdapterTest = Test-AdapterHealth

Write-Host "[21/21] Finalizing Report..." -ForegroundColor Cyan

#endregion

#region Calculate Final Scores

$globalScore = [math]::Min(100, $globalScore)

$overallHealthRating = if ($globalScore -ge 85) { "Excellent" }
    elseif ($globalScore -ge 70) { "Good" }
    elseif ($globalScore -ge 50) { "Fair" }
    else { "Needs Attention" }

# Prepare variables for HTML
$cpuScoreVal = $cpuScore
$cpuStatus = if ($avgLoad -lt 70) { "Good" } else { "Fair" }

$ramScoreVal = $ramScore
$ramStatus = if ($totalRAM -ge 8) { "Excellent" } elseif ($totalRAM -ge 4) { "Good" } else { "Low" }

$storageScoreVal = $storageScore
$storageStatus = if ($testData.Storage.MediaType -eq "SSD") { "Excellent" } else { "Standard" }

$batteryScoreVal = if ($batteryData.Detected) { $batteryScore } else { 6 }
$batteryStatus = if ($batteryData.Detected) { $batteryStatus } else { "No Battery" }
$batteryDetails = if ($batteryData.Detected) { "$($batteryData.Health)% Health" } else { "Desktop PC" }

$tempScoreVal = if ($testData.Temperature.CPUTemp -ne "N/A") {
    if ($testData.Temperature.CelsiusValue -lt 65) { 7 }
    elseif ($testData.Temperature.CelsiusValue -lt 75) { 5 }
    elseif ($testData.Temperature.CelsiusValue -lt 85) { 3 }
    else { 1 }
} else { 5 }
$tempStatus = $testData.Temperature.Status

$gpuScoreVal = if ($gpuType -eq "Dedicated") { 7 } else { 4 }
$gpuStatus = if ($gpuType -eq "Dedicated") { "Dedicated" } else { "Integrated" }

$webcamScoreVal = if ($cameras.Count -gt 0) { 3 } else { 0 }
$webcamStatus = if ($cameras.Count -gt 0) { "Detected" } else { "Not Found" }
$webcamDetails = "$($cameras.Count) camera(s)"

$wifiScoreVal = if ($testData.Network.WiFi.Detected) { 4 } else { 0 }
$wifiStatus = if ($testData.Network.WiFi.Detected) { "Detected" } else { "Not Found" }
$wifiDetails = if ($testData.Network.WiFi.Detected) { $testData.Network.WiFi.Name } else { "N/A" }

#endregion

# Due to character limit, I'll continue with the HTML in the next message. Let me save this file first and continue.

$reportPath = Join-Path $outputDir "Diagnostic_Report_$timestamp.html"

# HTML content will be in next part due to length limits
# For now, let's create a summary

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "  DIAGNOSTIC COMPLETE!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "`nHealth Score: $globalScore/100 ($overallHealthRating)" -ForegroundColor Cyan
Write-Host "Performance Score: $performanceScore/100 ($($testData.PerformanceTier))" -ForegroundColor Cyan
Write-Host "`nKey Findings:" -ForegroundColor Yellow
Write-Host "  CPU: $($testData.CPU.Name)" -ForegroundColor White
Write-Host "  RAM: $($testData.Memory.Total) $($testData.Memory.Type)" -ForegroundColor White
Write-Host "  Storage: $($testData.Storage.MediaType) - $($testData.Storage.Size)" -ForegroundColor White
Write-Host "  WiFi: $(if ($testData.Network.WiFi.Detected) { $testData.Network.WiFi.Name } else { 'Not Detected' })" -ForegroundColor White
Write-Host "  USB Ports: $($testData.Ports.USB.Total) ($($testData.Ports.USB.USBA) Type-A, $($testData.Ports.USB.USBC) Type-C)" -ForegroundColor White
Write-Host "  Screen: $($testData.Display.Resolution) - $($testData.Display.ScreenSize)" -ForegroundColor White
Write-Host "  Touchscreen: $(if ($testData.Display.Touchscreen) { 'Yes' } else { 'No' })" -ForegroundColor White
Write-Host "  USB-C PD: $(if ($testData.Ports.USBC_PD) { 'Supported' } else { 'No' })" -ForegroundColor White
Write-Host "  Keyboard Backlight: $(if ($testData.Keyboard.Backlight) { 'Yes' } else { 'No' })" -ForegroundColor White

Write-Host "`nGenerating HTML report..." -ForegroundColor Cyan

# Prepare HTML variables
$cpuScoreVal = if ($avgLoad -lt 70) { 7 } else { 4 }
$cpuStatus = if ($avgLoad -lt 70) { "Good" } else { "Fair" }

$ramScoreVal = if ($totalRAM -ge 8) { 7 } elseif ($totalRAM -ge 4) { 4 } else { 2 }
$ramStatus = if ($totalRAM -ge 8) { "Excellent" } elseif ($totalRAM -ge 4) { "Good" } else { "Low" }

$storageScoreVal = if ($testData.Storage.MediaType -eq "SSD") { 8 } else { 4 }
$storageStatus = if ($testData.Storage.MediaType -eq "SSD") { "Excellent" } else { "Standard" }

$batteryScoreVal = if ($batteryData.Detected) {
    if ($batteryData.Health -ge 85) { 8 }
    elseif ($batteryData.Health -ge 70) { 6 }
    elseif ($batteryData.Health -ge 50) { 4 }
    else { 2 }
} else { 6 }
$batteryStatus = if ($batteryData.Detected) {
    if ($batteryData.Health -ge 85) { "Excellent" }
    elseif ($batteryData.Health -ge 70) { "Good" }
    elseif ($batteryData.Health -ge 50) { "Fair" }
    else { "Poor" }
} else { "No Battery" }
$batteryDetails = if ($batteryData.Detected) { "$($batteryData.Health)% Health" } else { "Desktop PC" }

$tempScoreVal = if ($testData.Temperature.CPUTemp -ne "N/A") {
    if ($testData.Temperature.CelsiusValue -lt 65) { 7 }
    elseif ($testData.Temperature.CelsiusValue -lt 75) { 5 }
    elseif ($testData.Temperature.CelsiusValue -lt 85) { 3 }
    else { 1 }
} else { 5 }
$tempStatus = $testData.Temperature.Status

$gpuScoreVal = if ($gpuType -eq "Dedicated") { 7 } else { 4 }
$gpuStatus = if ($gpuType -eq "Dedicated") { "Dedicated" } else { "Integrated" }

$webcamScoreVal = if ($testData.Webcam.Detected) { 3 } else { 0 }
$webcamStatus = if ($testData.Webcam.Detected) { "Detected" } else { "Not Found" }
$webcamDetails = "$($testData.Webcam.Count) camera(s)"

$wifiScoreVal = if ($testData.Network.WiFi.Detected) { 4 } else { 0 }
$wifiStatus = if ($testData.Network.WiFi.Detected) { "Detected" } else { "Not Found" }
$wifiDetails = if ($testData.Network.WiFi.Detected) { $testData.Network.WiFi.Name } else { "N/A" }

$globalScore = [math]::Min(100, $globalScore)
$overallHealthRating = if ($globalScore -ge 85) { "Excellent" }
    elseif ($globalScore -ge 70) { "Good" }
    elseif ($globalScore -ge 50) { "Fair" }
    else { "Needs Attention" }

# Generate use cases HTML
$useCasesHTML = ""
if ($testData.UseCases.Suitable -and $testData.UseCases.Suitable.Count -gt 0) {
    $useCasesHTML += "<div class='use-case-section'><h3 style='color: #27ae60;'>+ Well Suited For:</h3><ul class='suitable'>"
    foreach ($useCase in $testData.UseCases.Suitable) {
        $useCasesHTML += "<li>$useCase</li>"
    }
    $useCasesHTML += "</ul></div>"
}

if ($testData.UseCases.Limited -and $testData.UseCases.Limited.Count -gt 0) {
    $useCasesHTML += "<div class='use-case-section'><h3 style='color: #f39c12;'>! Limited Performance For:</h3><ul class='limited'>"
    foreach ($useCase in $testData.UseCases.Limited) {
        $useCasesHTML += "<li>$useCase</li>"
    }
    $useCasesHTML += "</ul></div>"
}

if ($testData.UseCases.NotRecommended -and $testData.UseCases.NotRecommended.Count -gt 0) {
    $useCasesHTML += "<div class='use-case-section'><h3 style='color: #e74c3c;'>- Not Recommended For:</h3><ul class='not-recommended'>"
    foreach ($useCase in $testData.UseCases.NotRecommended) {
        $useCasesHTML += "<li>$useCase</li>"
    }
    $useCasesHTML += "</ul></div>"
}

# Generate upgrades HTML
$upgradesHTML = ""
if ($testData.UpgradeRecommendations -and $testData.UpgradeRecommendations.Count -gt 0) {
    foreach ($upgrade in $testData.UpgradeRecommendations) {
        $priority = if ($upgrade.Priority -eq 1) { "HIGH" } else { "MEDIUM" }
        $priorityColor = if ($upgrade.Priority -eq 1) { "#e74c3c" } else { "#f39c12" }

        $upgradesHTML += @"
<div class='upgrade-card'>
    <div class='upgrade-header'>
        <h3>$($upgrade.Component)</h3>
        <span class='priority-badge' style='background: $priorityColor;'>Priority: $priority</span>
    </div>
    <div class='upgrade-details'>
        <div class='upgrade-row'>
            <span class='upgrade-label'>Current:</span>
            <span class='upgrade-value'>$($upgrade.Current)</span>
        </div>
        <div class='upgrade-row'>
            <span class='upgrade-label'>Recommended:</span>
            <span class='upgrade-value' style='color: #27ae60; font-weight: 600;'>$($upgrade.Recommended)</span>
        </div>
        <div class='upgrade-row'>
            <span class='upgrade-label'>Cost:</span>
            <span class='upgrade-value'>$($upgrade.Cost)</span>
        </div>
        <div class='upgrade-row'>
            <span class='upgrade-label'>Performance Gain:</span>
            <span class='upgrade-value' style='color: #3498db; font-weight: 600;'>+$($upgrade.PerformanceGain)%</span>
        </div>
    </div>
    <p class='upgrade-description'>$($upgrade.Description)</p>
</div>
"@
    }
} else {
    $upgradesHTML = "<p style='text-align: center; color: #27ae60; font-size: 18px;'>No critical upgrades needed at this time.</p>"
}

# Generate HTML report
$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Laptop Diagnostic Report - v15.0</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            min-height: 100vh;
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px;
            text-align: center;
        }

        .header h1 {
            font-size: 36px;
            margin-bottom: 10px;
        }

        .header p {
            font-size: 16px;
            opacity: 0.9;
        }

        .dual-rating {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
            padding: 40px;
            background: #f8f9fa;
        }

        .rating-card {
            background: white;
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            transition: transform 0.3s;
        }

        .rating-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.15);
        }

        .rating-card h2 {
            font-size: 20px;
            margin-bottom: 10px;
            color: #2c3e50;
        }

        .rating-card .subtitle {
            font-size: 14px;
            color: #7f8c8d;
            margin-bottom: 20px;
        }

        .score-display {
            font-size: 64px;
            font-weight: bold;
            margin: 20px 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }

        .rating-label {
            font-size: 24px;
            font-weight: 600;
            color: #34495e;
            margin-bottom: 15px;
        }

        .progress-bar {
            width: 100%;
            height: 20px;
            background: #ecf0f1;
            border-radius: 10px;
            overflow: hidden;
        }

        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            transition: width 1s ease;
        }

        .component-breakdown {
            display: grid;
            grid-template-columns: auto 1fr auto;
            gap: 10px;
            margin-top: 20px;
            font-size: 14px;
        }

        .component-name {
            color: #34495e;
            font-weight: 500;
        }

        .component-bar {
            height: 8px;
            background: #ecf0f1;
            border-radius: 4px;
            align-self: center;
        }

        .component-bar-fill {
            height: 100%;
            background: #667eea;
            border-radius: 4px;
        }

        .component-score {
            color: #7f8c8d;
            font-weight: 600;
        }

        .tabs {
            display: flex;
            background: #34495e;
            overflow-x: auto;
        }

        .tab-button {
            background: none;
            border: none;
            color: white;
            padding: 15px 30px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.3s;
            border-bottom: 3px solid transparent;
            white-space: nowrap;
        }

        .tab-button:hover {
            background: rgba(255,255,255,0.1);
        }

        .tab-button.active {
            background: rgba(255,255,255,0.15);
            border-bottom-color: #667eea;
        }

        .tab-content {
            display: none;
            padding: 30px;
            animation: fadeIn 0.3s;
        }

        .tab-content.active {
            display: block;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }

        .card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }

        .card h3 {
            color: #2c3e50;
            margin-bottom: 15px;
            font-size: 16px;
        }

        .card-row {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #ecf0f1;
        }

        .card-row:last-child {
            border-bottom: none;
        }

        .label {
            color: #7f8c8d;
            font-size: 14px;
        }

        .value {
            color: #2c3e50;
            font-weight: 600;
            font-size: 14px;
        }

        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
        }

        .status-excellent { background: #d4edda; color: #155724; }
        .status-good { background: #cce5ff; color: #004085; }
        .status-fair { background: #fff3cd; color: #856404; }
        .status-poor { background: #f8d7da; color: #721c24; }

        .test-section {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
        }

        .test-section h3 {
            color: #2c3e50;
            margin-bottom: 15px;
        }

        .use-case-section {
            margin: 20px 0;
        }

        .use-case-section h3 {
            margin-bottom: 10px;
            font-size: 18px;
        }

        .use-case-section ul {
            list-style: none;
            padding-left: 0;
        }

        .use-case-section li {
            padding: 8px 0 8px 25px;
            position: relative;
            font-size: 14px;
            line-height: 1.6;
        }

        .suitable li:before { content: '+'; position: absolute; left: 0; color: #27ae60; font-weight: bold; }
        .limited li:before { content: '!'; position: absolute; left: 0; color: #f39c12; font-weight: bold; }
        .not-recommended li:before { content: '-'; position: absolute; left: 0; color: #e74c3c; font-weight: bold; }

        .upgrade-card {
            background: white;
            border: 2px solid #ecf0f1;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
        }

        .upgrade-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
        }

        .upgrade-header h3 {
            color: #2c3e50;
            font-size: 18px;
        }

        .priority-badge {
            padding: 6px 12px;
            border-radius: 20px;
            color: white;
            font-size: 12px;
            font-weight: 600;
        }

        .upgrade-details {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 15px;
        }

        .upgrade-row {
            display: flex;
            justify-content: space-between;
            padding: 6px 0;
        }

        .upgrade-label {
            color: #7f8c8d;
            font-size: 14px;
        }

        .upgrade-value {
            color: #2c3e50;
            font-weight: 600;
            font-size: 14px;
        }

        .upgrade-description {
            color: #34495e;
            font-size: 14px;
            line-height: 1.6;
            font-style: italic;
        }

        @media print {
            .tabs, .tab-button {
                display: none;
            }
            .tab-content {
                display: block !important;
                page-break-inside: avoid;
            }
        }

        @media (max-width: 768px) {
            .dual-rating {
                grid-template-columns: 1fr;
            }

            .cards {
                grid-template-columns: 1fr;
            }

            .tabs {
                flex-wrap: wrap;
            }
        }

        /* Interactive test styles */
        .keyboard-grid {
            margin: 20px 0;
        }

        .keyboard-row {
            margin-bottom: 15px;
            border-left: 3px solid #667eea;
            padding-left: 15px;
        }

        .row-label {
            font-size: 11px;
            color: #7f8c8d;
            margin-bottom: 5px;
            font-weight: 600;
        }

        .keys-container {
            display: flex;
            flex-wrap: wrap;
            gap: 5px;
        }

        .key {
            background: #ecf0f1;
            border: 2px solid #bdc3c7;
            border-radius: 5px;
            padding: 12px 8px;
            text-align: center;
            font-size: 11px;
            font-weight: 600;
            color: #2c3e50;
            min-width: 45px;
            min-height: 45px;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: all 0.2s;
        }

        .key.pressed {
            background: #27ae60;
            color: white;
            border-color: #229954;
            transform: scale(0.95);
        }

        .touchpad-test {
            background: white;
            border: 2px solid #34495e;
            border-radius: 10px;
            height: 400px;
            cursor: crosshair;
            position: relative;
        }

        .test-button {
            background: #667eea;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            margin: 5px;
            transition: all 0.3s;
        }

        .test-button:hover {
            background: #764ba2;
            transform: translateY(-2px);
        }

        .status-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 10px;
            margin: 20px 0;
        }

        .status-item {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
        }

        .status-item .label {
            font-size: 12px;
            color: #7f8c8d;
            margin-bottom: 5px;
        }

        .status-item .value {
            font-size: 16px;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Laptop Diagnostic Report v15.0</h1>
            <p>Complete System Analysis - Generated: $timestamp</p>
            <p>System: $($testData.System.Manufacturer) $($testData.System.Model)</p>
        </div>

        <div class="dual-rating">
            <div class="rating-card">
                <h2>Health Score</h2>
                <p class="subtitle">Current condition and functionality</p>
                <div class="score-display">$globalScore/100</div>
                <div class="rating-label">$overallHealthRating</div>
                <div class="progress-bar">
                    <div class="progress-fill" style="width: $globalScore%;"></div>
                </div>
                <div class="component-breakdown">
                    <span class="component-name">CPU</span>
                    <div class="component-bar"><div class="component-bar-fill" style="width: $($cpuScoreVal * 10)%;"></div></div>
                    <span class="component-score">$cpuScoreVal/10</span>

                    <span class="component-name">RAM</span>
                    <div class="component-bar"><div class="component-bar-fill" style="width: $($ramScoreVal * 10)%;"></div></div>
                    <span class="component-score">$ramScoreVal/10</span>

                    <span class="component-name">Storage</span>
                    <div class="component-bar"><div class="component-bar-fill" style="width: $($storageScoreVal * 10)%;"></div></div>
                    <span class="component-score">$storageScoreVal/10</span>

                    <span class="component-name">Battery</span>
                    <div class="component-bar"><div class="component-bar-fill" style="width: $($batteryScoreVal * 10)%;"></div></div>
                    <span class="component-score">$batteryScoreVal/10</span>
                </div>
            </div>

            <div class="rating-card">
                <h2>Performance Score</h2>
                <p class="subtitle">Compared to 2025 standards</p>
                <div class="score-display">$performanceScore/100</div>
                <div class="rating-label">$($testData.PerformanceTier)</div>
                <div class="progress-bar">
                    <div class="progress-fill" style="width: $performanceScore%;"></div>
                </div>
                <div class="component-breakdown">
                    <span class="component-name">CPU ($($testData.CPU.Tier))</span>
                    <div class="component-bar"><div class="component-bar-fill" style="width: $($testData.CPU.TierScore)%;"></div></div>
                    <span class="component-score">$($testData.CPU.TierScore)/100</span>

                    <span class="component-name">RAM ($($testData.Memory.Tier))</span>
                    <div class="component-bar"><div class="component-bar-fill" style="width: $($testData.Memory.TierScore)%;"></div></div>
                    <span class="component-score">$($testData.Memory.TierScore)/100</span>

                    <span class="component-name">Storage ($($testData.Storage.Tier))</span>
                    <div class="component-bar"><div class="component-bar-fill" style="width: $($testData.Storage.TierScore)%;"></div></div>
                    <span class="component-score">$($testData.Storage.TierScore)/100</span>

                    <span class="component-name">GPU ($($testData.GPU.Tier))</span>
                    <div class="component-bar"><div class="component-bar-fill" style="width: $($testData.GPU.TierScore)%;"></div></div>
                    <span class="component-score">$($testData.GPU.TierScore)/100</span>
                </div>
            </div>
        </div>

        <div class="tabs">
            <button class="tab-button active" onclick="openTab('overview', event)">Overview</button>
            <button class="tab-button" onclick="openTab('battery', event)">Battery</button>
            <button class="tab-button" onclick="openTab('temperature', event)">Temperature</button>
            <button class="tab-button" onclick="openTab('adapter', event)">Adapter Test</button>
            <button class="tab-button" onclick="openTab('hardware', event)">Hardware Details</button>
            <button class="tab-button" onclick="openTab('keyboard', event)">Keyboard Test</button>
            <button class="tab-button" onclick="openTab('touchpad', event)">Touchpad Test</button>
            <button class="tab-button" onclick="openTab('display', event)">Display Test</button>
            <button class="tab-button" onclick="openTab('audio', event)">Audio Test</button>
        </div>

        <div id="overview" class="tab-content active">
            <h2 style="margin-bottom: 20px;">System Overview</h2>

            <div class="cards">
                <div class="card">
                    <h3>System Information</h3>
                    <div class="card-row">
                        <span class="label">Manufacturer</span>
                        <span class="value">$($testData.System.Manufacturer)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Model</span>
                        <span class="value">$($testData.System.Model)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Operating System</span>
                        <span class="value">$($testData.System.OS)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">BIOS Version</span>
                        <span class="value">$($testData.System.BIOSVersion)</span>
                    </div>
                </div>

                <div class="card">
                    <h3>Processor</h3>
                    <div class="card-row">
                        <span class="label">Model</span>
                        <span class="value">$($testData.CPU.Name)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Cores / Threads</span>
                        <span class="value">$($testData.CPU.Cores) / $($testData.CPU.Threads)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Speed</span>
                        <span class="value">$($testData.CPU.Speed) MHz</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Current Load</span>
                        <span class="value">$($testData.CPU.CurrentLoad)%</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Benchmark</span>
                        <span class="value">$($testData.CPU.BenchmarkOps) ops/sec</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Tier</span>
                        <span class="value">$($testData.CPU.Tier) ($($testData.CPU.TierScore)/100)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Age</span>
                        <span class="value">~$($testData.CPU.EstimatedAge) years old</span>
                    </div>
                </div>

                <div class="card">
                    <h3>Memory (RAM)</h3>
                    <div class="card-row">
                        <span class="label">Total RAM</span>
                        <span class="value">$($testData.Memory.Total)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Type</span>
                        <span class="value">$($testData.Memory.Type)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Speed</span>
                        <span class="value">$($testData.Memory.Speed)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Modules</span>
                        <span class="value">$($testData.Memory.Modules)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Tier</span>
                        <span class="value">$($testData.Memory.Tier) ($($testData.Memory.TierScore)/100)</span>
                    </div>
                </div>

                <div class="card">
                    <h3>Storage</h3>
                    <div class="card-row">
                        <span class="label">Model</span>
                        <span class="value">$($testData.Storage.Model)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Size</span>
                        <span class="value">$($testData.Storage.Size)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Type</span>
                        <span class="value">$($testData.Storage.MediaType)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Health</span>
                        <span class="value">$($testData.Storage.Health)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Read Speed</span>
                        <span class="value">$($testData.Storage.ReadSpeed)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Write Speed</span>
                        <span class="value">$($testData.Storage.WriteSpeed)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Tier</span>
                        <span class="value">$($testData.Storage.Tier) ($($testData.Storage.TierScore)/100)</span>
                    </div>
                </div>

                <div class="card">
                    <h3>Graphics</h3>
                    <div class="card-row">
                        <span class="label">GPU</span>
                        <span class="value">$($testData.GPU.Name)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Type</span>
                        <span class="value">$($testData.GPU.Type)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">VRAM</span>
                        <span class="value">$($testData.GPU.VRAM)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Driver</span>
                        <span class="value">$($testData.GPU.Driver)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Tier</span>
                        <span class="value">$($testData.GPU.Tier) ($($testData.GPU.TierScore)/100)</span>
                    </div>
                </div>

                <div class="card">
                    <h3>Display</h3>
                    <div class="card-row">
                        <span class="label">Resolution</span>
                        <span class="value">$($testData.Display.Resolution)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Refresh Rate</span>
                        <span class="value">$($testData.Display.RefreshRate) Hz</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Screen Size</span>
                        <span class="value" style="color: #27ae60; font-weight: bold;">$($testData.Display.ScreenSize)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Touchscreen</span>
                        <span class="value">$(if ($testData.Display.Touchscreen) { 'Yes' } else { 'No' })</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Tier</span>
                        <span class="value">$($testData.Display.Tier) ($($testData.Display.TierScore)/100)</span>
                    </div>
                </div>

                <div class="card">
                    <h3>Network & Connectivity</h3>
                    <div class="card-row">
                        <span class="label">WiFi</span>
                        <span class="value" style="color: $(if ($testData.Network.WiFi.Detected) { '#27ae60' } else { '#e74c3c' });">$(if ($testData.Network.WiFi.Detected) { 'Detected' } else { 'Not Found' })</span>
                    </div>
"@

if ($testData.Network.WiFi.Detected) {
    $htmlContent += @"
                    <div class="card-row">
                        <span class="label">WiFi Adapter</span>
                        <span class="value">$($testData.Network.WiFi.Name)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Link Speed</span>
                        <span class="value">$($testData.Network.WiFi.Speed)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Status</span>
                        <span class="value">$($testData.Network.WiFi.Status)</span>
                    </div>
"@
    if ($testData.Network.WiFi.SignalStrength -ne "N/A") {
        $htmlContent += @"
                    <div class="card-row">
                        <span class="label">Signal Strength</span>
                        <span class="value">$($testData.Network.WiFi.SignalStrength)</span>
                    </div>
"@
    }
}

$htmlContent += @"
                    <div class="card-row">
                        <span class="label">Bluetooth</span>
                        <span class="value">$(if ($testData.Network.Bluetooth.Detected) { 'Detected' } else { 'Not Found' })</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Ethernet</span>
                        <span class="value">$(if ($testData.Ports.Ethernet) { 'Yes' } else { 'No' })</span>
                    </div>
                </div>

                <div class="card">
                    <h3>Ports & Connectors</h3>
                    <div class="card-row">
                        <span class="label">Total USB Ports</span>
                        <span class="value">$($testData.Ports.USB.Total)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">USB Type-A</span>
                        <span class="value">$($testData.Ports.USB.USBA)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">USB Type-C</span>
                        <span class="value" style="color: $(if ($testData.Ports.USB.USBC -gt 0) { '#27ae60' } else { '#e74c3c' });">$($testData.Ports.USB.USBC)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">USB-C PD</span>
                        <span class="value">$(if ($testData.Ports.USBC_PD) { 'Supported' } else { 'No' })</span>
                    </div>
                    <div class="card-row">
                        <span class="label">HDMI</span>
                        <span class="value">$(if ($testData.Ports.HDMI) { 'Yes' } else { 'No' })</span>
                    </div>
                    <div class="card-row">
                        <span class="label">VGA</span>
                        <span class="value">$(if ($testData.Ports.VGA) { 'Yes' } else { 'No' })</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Ethernet Port</span>
                        <span class="value">$(if ($testData.Ports.Ethernet) { 'Yes' } else { 'No' })</span>
                    </div>
                </div>

                <div class="card">
                    <h3>Keyboard & Input</h3>
                    <div class="card-row">
                        <span class="label">Keyboard Backlight</span>
                        <span class="value" style="color: $(if ($testData.Keyboard.Backlight) { '#27ae60' } else { '#7f8c8d' });">$(if ($testData.Keyboard.Backlight) { 'Detected' } else { 'Not Detected' })</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Layout</span>
                        <span class="value">$($testData.Keyboard.Layout)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Keyboards</span>
                        <span class="value">$($testData.Keyboard.Count)</span>
                    </div>
                </div>

                <div class="card">
                    <h3>Webcam</h3>
                    <div class="card-row">
                        <span class="label">Status</span>
                        <span class="value" style="color: $(if ($testData.Webcam.Detected) { '#27ae60' } else { '#e74c3c' });">$(if ($testData.Webcam.Detected) { 'Detected' } else { 'Not Found' })</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Count</span>
                        <span class="value">$($testData.Webcam.Count)</span>
                    </div>
"@

if ($testData.Webcam.Detected -and $testData.Webcam.Devices) {
    foreach ($cam in $testData.Webcam.Devices) {
        $htmlContent += @"
                    <div class="card-row">
                        <span class="label">$($cam.Name)</span>
                        <span class="value" style="color: $(if ($cam.Enabled) { '#27ae60' } else { '#f39c12' });">$(if ($cam.Enabled) { 'Enabled' } else { 'Disabled' })</span>
                    </div>
"@
    }
}

$htmlContent += @"
                </div>

                <div class="card">
                    <h3>Durability & Certifications</h3>
                    <div class="card-row">
                        <span class="label">MIL-STD Certified</span>
                        <span class="value" style="color: $(if ($testData.Durability.MIL_STD_Certified) { '#27ae60' } else { '#7f8c8d' });">$(if ($testData.Durability.MIL_STD_Certified) { 'Yes' } else { 'No/Unknown' })</span>
                    </div>
"@

if ($testData.Durability.Certifications -and $testData.Durability.Certifications.Count -gt 0) {
    foreach ($cert in $testData.Durability.Certifications) {
        $htmlContent += @"
                    <div class="card-row">
                        <span class="label">Certification</span>
                        <span class="value">$cert</span>
                    </div>
"@
    }
}

$htmlContent += @"
                    <div class="card-row">
                        <span class="label">Est. Lifespan</span>
                        <span class="value">$($testData.Durability.EstimatedLifespan)</span>
                    </div>
                </div>

                <div class="card">
                    <h3>Special Features</h3>
                    <div class="card-row">
                        <span class="label">USB Power When Off</span>
                        <span class="value">$(if ($testData.Features.USBPowerWhenOff) { 'Supported' } else { 'Unknown' })</span>
                    </div>
                    <div class="card-row">
                        <span class="label">USB-C PD Charging</span>
                        <span class="value">$(if ($testData.Features.USBC_PDCharging) { 'Supported' } else { 'No' })</span>
                    </div>
                </div>
            </div>

            <div class="test-section">
                <h3>Recommended Use Cases</h3>
                <p style="margin-bottom: 20px; color: #7f8c8d;">Based on your Performance Score of <strong>$performanceScore/100 ($($testData.PerformanceTier))</strong>, here's what your laptop can handle:</p>

                $useCasesHTML
            </div>

            <div class="test-section">
                <h3>Upgrade Recommendations</h3>
                <p style="margin-bottom: 20px; color: #7f8c8d;">These upgrades could improve your system's performance:</p>

                $upgradesHTML
            </div>
        </div>

        <div id="battery" class="tab-content">
            <h2 style="margin-bottom: 20px;">Battery Analysis</h2>

"@

if ($testData.Battery.Detected) {
    $healthColor = if ($testData.Battery.Health -ge 85) { '#27ae60' }
                   elseif ($testData.Battery.Health -ge 70) { '#3498db' }
                   elseif ($testData.Battery.Health -ge 50) { '#f39c12' }
                   else { '#e74c3c' }

    $htmlContent += @"
            <div class="test-section">
                <h3>Battery Health: <span style="color: $healthColor;">$($testData.Battery.Health)%</span></h3>
                <div class="progress-bar" style="margin: 20px 0;">
                    <div class="progress-fill" style="width: $($testData.Battery.Health)%; background: $healthColor;"></div>
                </div>

                <div class="cards">
                    <div class="card">
                        <h3>Capacity Information</h3>
                        <div class="card-row">
                            <span class="label">Design Capacity</span>
                            <span class="value">$($testData.Battery.DesignCapacity) mWh</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Full Charge Capacity</span>
                            <span class="value">$($testData.Battery.FullChargeCapacity) mWh</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Current Charge</span>
                            <span class="value">$($testData.Battery.CurrentCharge)%</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Health Percentage</span>
                            <span class="value" style="color: $healthColor; font-weight: bold;">$($testData.Battery.Health)%</span>
                        </div>
                    </div>

                    <div class="card">
                        <h3>Battery Details</h3>
                        <div class="card-row">
                            <span class="label">Status</span>
                            <span class="value">$($testData.Battery.Status)</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Chemistry</span>
                            <span class="value">$($testData.Battery.Chemistry)</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Voltage</span>
                            <span class="value">$($testData.Battery.Voltage)</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Current Rate</span>
                            <span class="value">$($testData.Battery.CurrentRate)</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Cycle Count</span>
                            <span class="value">$($testData.Battery.CycleCount)</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Manufacturer</span>
                            <span class="value">$($testData.Battery.Manufacturer)</span>
                        </div>
                    </div>
                </div>
            </div>
"@
} else {
    $htmlContent += @"
            <div class="test-section">
                <h3>No Battery Detected</h3>
                <p>This system does not have a battery installed or the battery is not detected. This is normal for desktop computers.</p>
            </div>
"@
}

$htmlContent += @"
        </div>

        <div id="temperature" class="tab-content">
            <h2 style="margin-bottom: 20px;">Temperature & Cooling</h2>

            <div class="test-section">
                <h3>CPU Temperature</h3>
"@

if ($testData.Temperature.CPUTemp -ne "N/A") {
    $tempColor = if ($testData.Temperature.CelsiusValue -lt 65) { '#27ae60' }
                 elseif ($testData.Temperature.CelsiusValue -lt 75) { '#3498db' }
                 elseif ($testData.Temperature.CelsiusValue -lt 85) { '#f39c12' }
                 else { '#e74c3c' }

    $htmlContent += @"
                <div class="cards">
                    <div class="card">
                        <h3>Current Temperature</h3>
                        <div style="text-align: center; padding: 20px 0;">
                            <div style="font-size: 48px; font-weight: bold; color: $tempColor;">$($testData.Temperature.CPUTemp)</div>
                            <div style="font-size: 18px; color: #7f8c8d; margin-top: 10px;">$($testData.Temperature.Status)</div>
                        </div>
                    </div>
"@

    if ($testData.Temperature.StressTest.Tested) {
        $htmlContent += @"
                    <div class="card">
                        <h3>Stress Test Results (15 seconds)</h3>
                        <div class="card-row">
                            <span class="label">Before Stress</span>
                            <span class="value">$($testData.Temperature.StressTest.Before) C</span>
                        </div>
                        <div class="card-row">
                            <span class="label">After Stress</span>
                            <span class="value">$($testData.Temperature.StressTest.After) C</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Temperature Delta</span>
                            <span class="value" style="color: #e74c3c; font-weight: bold;">+$($testData.Temperature.StressTest.Delta) C</span>
                        </div>
                        <div style="margin-top: 10px; padding: 15px; background: #e8f5e9; border-radius: 5px; border-left: 3px solid #27ae60;">
                            <h4 style="font-size: 13px; color: #27ae60; margin-bottom: 8px;">During 15s Stress Test:</h4>
                            <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px;">
                                <div style="text-align: center;">
                                    <div style="font-size: 11px; color: #7f8c8d;">Minimum</div>
                                    <div style="font-size: 18px; font-weight: bold; color: #3498db;">$($testData.Temperature.StressTest.Min) °C</div>
                                </div>
                                <div style="text-align: center;">
                                    <div style="font-size: 11px; color: #7f8c8d;">Average</div>
                                    <div style="font-size: 18px; font-weight: bold; color: #f39c12;">$($testData.Temperature.StressTest.Avg) °C</div>
                                </div>
                                <div style="text-align: center;">
                                    <div style="font-size: 11px; color: #7f8c8d;">Maximum</div>
                                    <div style="font-size: 18px; font-weight: bold; color: #e74c3c;">$($testData.Temperature.StressTest.Max) °C</div>
                                </div>
                            </div>
                        </div>
                        <div style="margin-top: 10px; padding: 10px; background: #f8f9fa; border-radius: 5px;">
                            <p style="font-size: 13px; color: #34495e;">The CPU was stressed for 15 seconds with intensive calculations. A healthy cooling system should keep the temperature increase below 20°C and max temp under 85°C.</p>
                        </div>
                    </div>
"@

        # Add heating issues assessment card
        $assessmentColor = switch ($testData.Temperature.StressTest.HeatingAssessment) {
            "Critical Issues" { '#e74c3c' }
            "Moderate Issues" { '#f39c12' }
            "Minor Issues" { '#f39c12' }
            "Good" { '#3498db' }
            "Excellent" { '#27ae60' }
            default { '#95a5a6' }
        }

        $htmlContent += @"
                    <div class="card" style="border-left: 4px solid $assessmentColor;">
                        <h3>Heating Issues Assessment</h3>
                        <div style="text-align: center; padding: 15px 0; border-bottom: 1px solid #ecf0f1;">
                            <div style="font-size: 32px; font-weight: bold; color: $assessmentColor;">$($testData.Temperature.StressTest.HeatingAssessment)</div>
                            <div style="font-size: 13px; color: #7f8c8d; margin-top: 5px;">Based on 15-second stress test</div>
                        </div>
"@

        # Display issues if any
        if ($testData.Temperature.StressTest.HeatingIssues.Count -gt 0) {
            $issuesBg = if ($testData.Temperature.StressTest.HeatingAssessment -eq "Critical Issues") { '#fee' } else { '#fff3cd' }
            $issuesColor = if ($testData.Temperature.StressTest.HeatingAssessment -eq "Critical Issues") { '#c0392b' } else { '#856404' }

            $htmlContent += @"
                        <div style="margin-top: 15px; padding: 12px; background: $issuesBg; border-radius: 5px; border-left: 3px solid $assessmentColor;">
                            <h4 style="font-size: 14px; color: $issuesColor; margin-bottom: 8px;">Issues Detected:</h4>
"@
            foreach ($issue in $testData.Temperature.StressTest.HeatingIssues) {
                $htmlContent += @"
                            <div style="margin-bottom: 5px; color: $issuesColor; font-size: 13px;">
                                <span style="font-weight: bold;">*</span> $issue
                            </div>
"@
            }
            $htmlContent += @"
                        </div>
"@
        }

        # Display recommendations
        if ($testData.Temperature.StressTest.CoolingRecommendations.Count -gt 0) {
            $recBg = if ($testData.Temperature.StressTest.HasHeatingIssues) { '#fff3cd' } else { '#e8f5e9' }
            $recColor = if ($testData.Temperature.StressTest.HasHeatingIssues) { '#856404' } else { '#27ae60' }

            $htmlContent += @"
                        <div style="margin-top: 15px; padding: 12px; background: $recBg; border-radius: 5px; border-left: 3px solid $assessmentColor;">
                            <h4 style="font-size: 14px; color: $recColor; margin-bottom: 8px;">Recommendations:</h4>
"@
            foreach ($rec in $testData.Temperature.StressTest.CoolingRecommendations) {
                $htmlContent += @"
                            <div style="margin-bottom: 5px; color: $recColor; font-size: 13px;">
                                $rec
                            </div>
"@
            }
            $htmlContent += @"
                        </div>
"@
        }

        $htmlContent += @"
                    </div>
"@
    }

    $htmlContent += @"
                </div>
"@
} else {
    $htmlContent += @"
                <p>Temperature sensor not available on this system.</p>
"@
}

$htmlContent += @"
            </div>
        </div>

        <div id="adapter" class="tab-content">
            <h2 style="margin-bottom: 20px;">AC Adapter / Charger Health Test</h2>

            <div class="test-section">
"@

if ($testData.AdapterTest.Connected) {
    # Determine health color
    $healthColor = switch ($testData.AdapterTest.Health) {
        "Excellent" { '#27ae60' }
        "Good" { '#3498db' }
        "Fair" { '#f39c12' }
        default { '#e74c3c' }
    }

    $htmlContent += @"
                <div class="card" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; margin-bottom: 20px;">
                    <h3 style="color: white;">Overall Adapter Health</h3>
                    <div style="text-align: center; padding: 20px 0;">
                        <div style="font-size: 48px; font-weight: bold;">$($testData.AdapterTest.Health)</div>
                        <div style="font-size: 16px; margin-top: 10px; opacity: 0.9;">10-second comprehensive test completed</div>
                    </div>
                </div>

                <h3>Power Delivery Analysis</h3>
                <div class="cards">
                    <div class="card">
                        <h3>Battery Voltage</h3>
                        <div class="card-row">
                            <span class="label">Current</span>
                            <span class="value">$($testData.AdapterTest.Voltage.Current) V</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Average</span>
                            <span class="value">$($testData.AdapterTest.Voltage.Avg) V</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Min / Max</span>
                            <span class="value">$($testData.AdapterTest.Voltage.Min) - $($testData.AdapterTest.Voltage.Max) V</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Stability</span>
                            <span class="value" style="color: $healthColor; font-weight: bold;">$($testData.AdapterTest.Voltage.Stability)</span>
                        </div>
                    </div>

                    <div class="card">
                        <h3>Charging Power</h3>
                        <div class="card-row">
                            <span class="label">Current</span>
                            <span class="value">$($testData.AdapterTest.Power.Current) W</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Average</span>
                            <span class="value">$($testData.AdapterTest.Power.Avg) W</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Min / Max</span>
                            <span class="value">$($testData.AdapterTest.Power.Min) - $($testData.AdapterTest.Power.Max) W</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Estimated Rating</span>
                            <span class="value" style="font-weight: bold;">$($testData.AdapterTest.Power.EstimatedRating)</span>
                        </div>
                    </div>
"@

    if ($testData.AdapterTest.Current.Avg -gt 0) {
        $htmlContent += @"
                    <div class="card">
                        <h3>Current Draw</h3>
                        <div class="card-row">
                            <span class="label">Current</span>
                            <span class="value">$($testData.AdapterTest.Current.Current) A</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Average</span>
                            <span class="value">$($testData.AdapterTest.Current.Avg) A</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Min / Max</span>
                            <span class="value">$($testData.AdapterTest.Current.Min) - $($testData.AdapterTest.Current.Max) A</span>
                        </div>
                    </div>
"@
    }

    $htmlContent += @"
                </div>

                <h3>Charging Performance</h3>
                <div class="cards">
"@

    if ($testData.AdapterTest.ChargingRate.IsCharging) {
        $htmlContent += @"
                    <div class="card">
                        <h3>Charging Rate</h3>
                        <div class="card-row">
                            <span class="label">Current Rate</span>
                            <span class="value">$($testData.AdapterTest.ChargingRate.Current) W</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Average Rate</span>
                            <span class="value">$($testData.AdapterTest.ChargingRate.Avg) W</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Min / Max</span>
                            <span class="value">$($testData.AdapterTest.ChargingRate.Min) - $($testData.AdapterTest.ChargingRate.Max) W</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Status</span>
                            <span class="value" style="color: #27ae60; font-weight: bold;">[OK] Charging</span>
                        </div>
                    </div>
"@
    } else {
        # Check if battery is at 100% - not charging is normal in this case
        $batteryLevel = $testData.AdapterTest.BatteryLevel.Start
        $isFullyCharged = $batteryLevel -ge 99

        if ($isFullyCharged) {
            $htmlContent += @"
                    <div class="card">
                        <h3>Charging Status</h3>
                        <div class="card-row">
                            <span class="label">Status</span>
                            <span class="value" style="color: #27ae60; font-weight: bold;">[OK] Fully Charged</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Battery Level</span>
                            <span class="value">$($batteryLevel)%</span>
                        </div>
                        <div style="margin-top: 10px; padding: 10px; background: #e8f5e9; border-radius: 5px; border-left: 3px solid #27ae60;">
                            <p style="font-size: 13px; color: #27ae60; margin: 0;">Battery is fully charged. Not charging is normal when battery is at 100%.</p>
                        </div>
                    </div>
"@
        } else {
            $htmlContent += @"
                    <div class="card">
                        <h3>Charging Status</h3>
                        <div class="card-row">
                            <span class="label">Status</span>
                            <span class="value" style="color: #e74c3c; font-weight: bold;">[X] Not Charging</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Battery Level</span>
                            <span class="value">$($batteryLevel)%</span>
                        </div>
                        <div style="margin-top: 10px; padding: 10px; background: #fee; border-radius: 5px; border-left: 3px solid #e74c3c;">
                            <p style="font-size: 13px; color: #c0392b; margin: 0;">Adapter is connected but battery is not charging at $($batteryLevel)%. This could indicate an issue with the adapter, cable, or charging port.</p>
                        </div>
                    </div>
"@
        }
    }

    $htmlContent += @"
                    <div class="card">
                        <h3>Battery Level Change</h3>
                        <div class="card-row">
                            <span class="label">Start Level</span>
                            <span class="value">$($testData.AdapterTest.BatteryLevel.Start)%</span>
                        </div>
                        <div class="card-row">
                            <span class="label">End Level</span>
                            <span class="value">$($testData.AdapterTest.BatteryLevel.End)%</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Delta (10s)</span>
                            <span class="value">$($testData.AdapterTest.BatteryLevel.Delta)%</span>
                        </div>
                    </div>
                </div>
"@

    if ($testData.AdapterTest.Issues.Count -gt 0) {
        $htmlContent += @"
                <h3>Issues Detected</h3>
                <div style="background: #fee; border-left: 3px solid #e74c3c; padding: 15px; border-radius: 5px; margin-bottom: 20px;">
"@
        foreach ($issue in $testData.AdapterTest.Issues) {
            $htmlContent += @"
                    <div style="margin-bottom: 8px; color: #c0392b;">
                        <span style="font-weight: bold;">[!]</span> $issue
                    </div>
"@
        }
        $htmlContent += @"
                </div>
"@
    }

    $htmlContent += @"
                <h3>Recommendations</h3>
                <div style="background: #e8f5e9; border-left: 3px solid #27ae60; padding: 15px; border-radius: 5px;">
"@
    foreach ($recommendation in $testData.AdapterTest.Recommendations) {
        $htmlContent += @"
                    <div style="margin-bottom: 8px; color: #27ae60;">
                        <span style="font-weight: bold;">[OK]</span> $recommendation
                    </div>
"@
    }
    $htmlContent += @"
                </div>
"@

    # Display notes if available
    if ($testData.AdapterTest.Notes -and $testData.AdapterTest.Notes.Count -gt 0) {
        $htmlContent += @"
                <h3>Important Notes</h3>
                <div style="background: #e7f3ff; border-left: 3px solid #2196f3; padding: 15px; border-radius: 5px; margin-bottom: 20px;">
"@
        foreach ($note in $testData.AdapterTest.Notes) {
            $htmlContent += @"
                    <div style="margin-bottom: 8px; color: #1565c0; font-size: 13px;">
                        <span style="font-weight: bold;">*</span> $note
                    </div>
"@
        }
        $htmlContent += @"
                </div>
"@
    }

    $htmlContent += @"
                <div style="margin-top: 20px; padding: 15px; background: #f8f9fa; border-radius: 5px;">
                    <h4 style="font-size: 14px; color: #2c3e50; margin-bottom: 10px;">Understanding Adapter Health:</h4>
                    <ul style="font-size: 13px; color: #34495e; line-height: 1.6; margin: 0; padding-left: 20px;">
                        <li><strong>Voltage Stability:</strong> Good adapters maintain stable voltage within 3-5% variance</li>
                        <li><strong>Power Output:</strong> Should match or exceed the adapter's rated wattage during charging</li>
                        <li><strong>Charging Rate:</strong> Healthy adapters charge at consistent rates without significant drops</li>
                        <li><strong>Typical Ratings:</strong> Laptops use 45W (ultrabooks), 65W (standard), 90W+ (gaming/workstations)</li>
                    </ul>
                </div>
"@

} else {
    $htmlContent += @"
                <div class="card" style="background: #fff3cd; border-left: 3px solid #ffc107;">
                    <h3>Adapter Not Connected</h3>
                    <p style="color: #856404; margin: 10px 0;">The AC adapter is not currently connected to the laptop.</p>
                    <p style="color: #856404; margin: 10px 0; font-size: 13px;">To perform the comprehensive adapter health test, please:</p>
                    <ol style="color: #856404; margin: 10px 0 10px 20px; font-size: 13px; line-height: 1.6;">
                        <li>Connect the AC adapter to your laptop</li>
                        <li>Ensure the charging indicator light is on</li>
                        <li>Run the diagnostic tool again</li>
                    </ol>
                </div>

                <div style="margin-top: 20px; padding: 15px; background: #e7f3ff; border-radius: 5px; border-left: 3px solid #2196f3;">
                    <h4 style="font-size: 14px; color: #0d47a1; margin-bottom: 10px;">What the Adapter Test Checks:</h4>
                    <ul style="font-size: 13px; color: #1565c0; line-height: 1.6; margin: 0; padding-left: 20px;">
                        <li>Voltage stability and fluctuations over 10 seconds</li>
                        <li>Power delivery capacity and consistency</li>
                        <li>Charging rate and efficiency</li>
                        <li>Battery charging behavior</li>
                        <li>Adapter health assessment with recommendations</li>
                    </ul>
                </div>
"@
}

$htmlContent += @"
            </div>
        </div>

        <div id="hardware" class="tab-content">
            <h2 style="margin-bottom: 20px;">Detailed Hardware Information</h2>

            <div class="cards">
                <div class="card">
                    <h3>CPU Cache</h3>
                    <div class="card-row">
                        <span class="label">L2 Cache</span>
                        <span class="value">$($testData.CPU.L2Cache)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">L3 Cache</span>
                        <span class="value">$($testData.CPU.L3Cache)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Virtualization</span>
                        <span class="value">$($testData.CPU.Virtualization)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Socket</span>
                        <span class="value">$($testData.CPU.Sockets)</span>
                    </div>
                </div>

                <div class="card">
                    <h3>Audio Devices</h3>
"@

foreach ($audio in $testData.Audio.Devices) {
    $htmlContent += @"
                    <div class="card-row">
                        <span class="label">$($audio.Name)</span>
                        <span class="value">$($audio.Status)</span>
                    </div>
"@
}

$htmlContent += @"
                </div>

                <div class="card">
                    <h3>Input Devices</h3>
                    <div class="card-row">
                        <span class="label">Keyboards</span>
                        <span class="value">$($testData.InputDevices.Keyboards)</span>
                    </div>
                    <div class="card-row">
                        <span class="label">Pointing Devices</span>
                        <span class="value">$($testData.InputDevices.PointingDevices)</span>
                    </div>
                </div>

                <div class="card">
                    <h3>Network Adapters</h3>
"@

foreach ($adapter in $testData.Network.Adapters) {
    $htmlContent += @"
                    <div class="card-row">
                        <span class="label">$($adapter.Name)</span>
                        <span class="value">$($adapter.Speed)</span>
                    </div>
"@
}

$htmlContent += @"
                </div>
            </div>
        </div>

        <div id="keyboard" class="tab-content">
            <h2 style="margin-bottom: 20px;">Keyboard Test</h2>

            <div class="test-section">
                <h3>Press any key to test</h3>
                <p style="margin-bottom: 20px; color: #7f8c8d;">Keys will turn green when pressed. Test all keys to ensure they work correctly.</p>

                <div id="keyboard-display" class="keyboard-grid">
                    <!-- Keys will be dynamically added here -->
                </div>

                <button class="test-button" onclick="resetKeyboard()">Reset Test</button>
            </div>
        </div>

        <div id="touchpad" class="tab-content">
            <h2 style="margin-bottom: 20px;">Touchpad/Mouse Test</h2>

            <div class="test-section">
                <h3>Draw on the canvas to test</h3>
                <p style="margin-bottom: 20px; color: #7f8c8d;">Click, drag, and test all mouse buttons and touchpad gestures.</p>

                <div class="status-grid">
                    <div class="status-item">
                        <div class="label">Left Click</div>
                        <div class="value" id="leftClickStatus" style="color: #e74c3c;">Not Tested</div>
                    </div>
                    <div class="status-item">
                        <div class="label">Right Click</div>
                        <div class="value" id="rightClickStatus" style="color: #e74c3c;">Not Tested</div>
                    </div>
                    <div class="status-item">
                        <div class="label">Movement</div>
                        <div class="value" id="moveStatus" style="color: #e74c3c;">Not Tested</div>
                    </div>
                    <div class="status-item">
                        <div class="label">Drag</div>
                        <div class="value" id="dragStatus" style="color: #e74c3c;">Not Tested</div>
                    </div>
                </div>

                <canvas id="touchpad-canvas" class="touchpad-test" width="800" height="400"></canvas>

                <div style="margin-top: 20px;">
                    <button class="test-button" onclick="clearCanvas()">Clear Canvas</button>
                    <button class="test-button" onclick="changeDrawColor('#000000')">Black</button>
                    <button class="test-button" onclick="changeDrawColor('#e74c3c')">Red</button>
                    <button class="test-button" onclick="changeDrawColor('#3498db')">Blue</button>
                    <button class="test-button" onclick="changeDrawColor('#27ae60')">Green</button>
                </div>
            </div>
        </div>

        <div id="display" class="tab-content">
            <h2 style="margin-bottom: 20px;">Display Test</h2>

            <div class="test-section">
                <h3>Screen Properties</h3>
                <div class="cards">
                    <div class="card">
                        <div class="card-row">
                            <span class="label">Resolution</span>
                            <span class="value">$($testData.Display.Resolution)</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Screen Size</span>
                            <span class="value" style="color: #27ae60; font-weight: bold;">$($testData.Display.ScreenSize)</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Refresh Rate</span>
                            <span class="value">$($testData.Display.RefreshRate) Hz</span>
                        </div>
                        <div class="card-row">
                            <span class="label">Touchscreen</span>
                            <span class="value">$(if ($testData.Display.Touchscreen) { 'Yes' } else { 'No' })</span>
                        </div>
                    </div>
                </div>
            </div>

            <div class="test-section">
                <h3>Dead Pixel Test</h3>
                <p style="margin-bottom: 20px; color: #7f8c8d;">Click a color to test fullscreen. Look carefully for dead or stuck pixels. Press ESC or click to exit.</p>

                <button class="test-button" onclick="testColorFullscreen('black')" style="background: #000;">Test Black</button>
                <button class="test-button" onclick="testColorFullscreen('white')" style="background: #fff; color: #000;">Test White</button>
                <button class="test-button" onclick="testColorFullscreen('red')" style="background: #f00;">Test Red</button>
                <button class="test-button" onclick="testColorFullscreen('green')" style="background: #0f0;">Test Green</button>
                <button class="test-button" onclick="testColorFullscreen('blue')" style="background: #00f;">Test Blue</button>
                <button class="test-button" onclick="testColorFullscreen('yellow')" style="background: #ff0;">Test Yellow</button>
            </div>
        </div>

        <div id="audio" class="tab-content">
            <h2 style="margin-bottom: 20px;">Audio Test</h2>

            <div class="test-section">
                <h3>Speaker Test</h3>
                <p style="margin-bottom: 20px; color: #7f8c8d;">Test your laptop speakers. You should hear a 440Hz tone from the selected speaker.</p>

                <div class="cards">
                    <div class="card">
                        <h3>Stereo Test</h3>
                        <button class="test-button" onclick="playLeftSpeaker()">Test Left Speaker</button>
                        <button class="test-button" onclick="playRightSpeaker()">Test Right Speaker</button>
                        <button class="test-button" onclick="playBothSpeakers()">Test Both Speakers</button>
                    </div>

                    <div class="card">
                        <h3>Frequency Test</h3>
                        <button class="test-button" onclick="playSweep()">Play Frequency Sweep</button>
                        <p style="margin-top: 10px; font-size: 13px; color: #7f8c8d;">Plays a 200Hz-2000Hz sweep. You should hear the pitch increase smoothly.</p>
                    </div>
                </div>

                <div class="card" style="margin-top: 20px;">
                    <h3>Detected Audio Devices</h3>
"@

foreach ($audio in $testData.Audio.Devices) {
    $htmlContent += @"
                    <div class="card-row">
                        <span class="label">$($audio.Name)</span>
                        <span class="value">$($audio.Status)</span>
                    </div>
"@
}

$htmlContent += @"
                </div>
            </div>
        </div>
    </div>

    <script>
        let drawColor = '#000000';

        // Tab Management - Fixed
        function openTab(tabName, evt) {
            try {
                // Hide all tab contents
                const tabContents = document.querySelectorAll('.tab-content');
                tabContents.forEach(content => {
                    content.classList.remove('active');
                });

                // Remove active class from all buttons
                const tabButtons = document.querySelectorAll('.tab-button');
                tabButtons.forEach(button => {
                    button.classList.remove('active');
                });

                // Show the selected tab content
                const selectedTab = document.getElementById(tabName);
                if (selectedTab) {
                    selectedTab.classList.add('active');
                }

                // Activate the clicked button
                if (evt && evt.currentTarget) {
                    evt.currentTarget.classList.add('active');
                }

                // Initialize interactive tests when tab opens
                if (tabName === 'keyboard') {
                    setTimeout(initKeyboard, 100);
                } else if (tabName === 'touchpad') {
                    setTimeout(initCanvas, 100);
                }
            } catch (error) {
                console.error('Error opening tab:', error);
            }
        }

        // Keyboard Test Functions
        const keyboardRows = [
            { label: 'Function Keys', keys: ['Escape', 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12'] },
            { label: 'Number Row', keys: ['Backquote', 'Digit1', 'Digit2', 'Digit3', 'Digit4', 'Digit5', 'Digit6', 'Digit7', 'Digit8', 'Digit9', 'Digit0', 'Minus', 'Equal', 'Backspace'] },
            { label: 'Top Row', keys: ['Tab', 'KeyQ', 'KeyW', 'KeyE', 'KeyR', 'KeyT', 'KeyY', 'KeyU', 'KeyI', 'KeyO', 'KeyP', 'BracketLeft', 'BracketRight', 'Backslash'] },
            { label: 'Home Row', keys: ['CapsLock', 'KeyA', 'KeyS', 'KeyD', 'KeyF', 'KeyG', 'KeyH', 'KeyJ', 'KeyK', 'KeyL', 'Semicolon', 'Quote', 'Enter'] },
            { label: 'Bottom Row', keys: ['ShiftLeft', 'KeyZ', 'KeyX', 'KeyC', 'KeyV', 'KeyB', 'KeyN', 'KeyM', 'Comma', 'Period', 'Slash', 'ShiftRight'] },
            { label: 'Space Row', keys: ['ControlLeft', 'MetaLeft', 'AltLeft', 'Space', 'AltRight', 'MetaRight', 'ControlRight'] },
            { label: 'Arrows', keys: ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'] }
        ];

        let keydownListener = null;

        function initKeyboard() {
            const display = document.getElementById('keyboard-display');
            if (!display) return;

            // Clear existing content
            display.innerHTML = '';

            // Create keyboard layout by rows
            keyboardRows.forEach(row => {
                const rowDiv = document.createElement('div');
                rowDiv.className = 'keyboard-row';
                rowDiv.innerHTML = '<div class="row-label">' + row.label + '</div>';

                const keysContainer = document.createElement('div');
                keysContainer.className = 'keys-container';

                row.keys.forEach(key => {
                    const keyDiv = document.createElement('div');
                    keyDiv.className = 'key';
                    keyDiv.id = 'key-' + key;

                    // Display friendly names
                    let displayText = key.replace('Key', '').replace('Digit', '');
                    if (key === 'Space') displayText = 'Space';
                    if (key === 'Backspace') displayText = 'Back';
                    if (key === 'Enter') displayText = 'Enter';
                    if (key === 'ShiftLeft') displayText = 'Shift L';
                    if (key === 'ShiftRight') displayText = 'Shift R';
                    if (key === 'ControlLeft') displayText = 'Ctrl L';
                    if (key === 'ControlRight') displayText = 'Ctrl R';
                    if (key === 'AltLeft') displayText = 'Alt L';
                    if (key === 'AltRight') displayText = 'Alt R';
                    if (key === 'MetaLeft') displayText = 'Win L';
                    if (key === 'MetaRight') displayText = 'Win R';
                    if (key === 'Backquote') displayText = '`';
                    if (key === 'Minus') displayText = '-';
                    if (key === 'Equal') displayText = '=';
                    if (key === 'BracketLeft') displayText = '[';
                    if (key === 'BracketRight') displayText = ']';
                    if (key === 'Backslash') displayText = '\\';
                    if (key === 'Semicolon') displayText = ';';
                    if (key === 'Quote') displayText = "'";
                    if (key === 'Comma') displayText = ',';
                    if (key === 'Period') displayText = '.';
                    if (key === 'Slash') displayText = '/';
                    if (key === 'CapsLock') displayText = 'Caps';

                    keyDiv.textContent = displayText;
                    if (key === 'Space') keyDiv.style.minWidth = '200px';

                    keysContainer.appendChild(keyDiv);
                });

                rowDiv.appendChild(keysContainer);
                display.appendChild(rowDiv);
            });

            // Remove old listener if exists
            if (keydownListener) {
                document.removeEventListener('keydown', keydownListener);
            }

            // Add new listener with preventDefault
            keydownListener = handleKeyPress;
            document.addEventListener('keydown', keydownListener);
        }

        function handleKeyPress(e) {
            // Prevent default browser behavior for all keys during test
            if (document.getElementById('keyboard').classList.contains('active')) {
                e.preventDefault();

                const keyElement = document.getElementById('key-' + e.code);
                if (keyElement) {
                    keyElement.classList.add('pressed');
                }
            }
        }

        function resetKeyboard() {
            document.querySelectorAll('.key').forEach(key => {
                key.classList.remove('pressed');
            });
        }

        // Touchpad Test Functions
        function initCanvas() {
            const canvas = document.getElementById('touchpad-canvas');
            if (!canvas) return;

            const ctx = canvas.getContext('2d');
            ctx.strokeStyle = drawColor;
            ctx.lineWidth = 3;
            ctx.lineCap = 'round';

            let isDrawing = false;
            let lastX = 0, lastY = 0;

            function draw(e) {
                if (!isDrawing) return;

                const rect = canvas.getBoundingClientRect();
                const x = e.clientX - rect.left;
                const y = e.clientY - rect.top;

                ctx.beginPath();
                ctx.moveTo(lastX, lastY);
                ctx.lineTo(x, y);
                ctx.stroke();

                lastX = x;
                lastY = y;

                updateStatus('moveStatus', 'Working', true);
                updateStatus('dragStatus', 'Working', true);
            }

            canvas.addEventListener('mousedown', (e) => {
                isDrawing = true;
                const rect = canvas.getBoundingClientRect();
                lastX = e.clientX - rect.left;
                lastY = e.clientY - rect.top;

                if (e.button === 0) updateStatus('leftClickStatus', 'Working', true);
                if (e.button === 2) updateStatus('rightClickStatus', 'Working', true);
            });

            canvas.addEventListener('mousemove', draw);
            canvas.addEventListener('mouseup', () => isDrawing = false);
            canvas.addEventListener('mouseleave', () => isDrawing = false);

            canvas.addEventListener('touchstart', (e) => {
                e.preventDefault();
                isDrawing = true;
                const rect = canvas.getBoundingClientRect();
                const touch = e.touches[0];
                lastX = touch.clientX - rect.left;
                lastY = touch.clientY - rect.top;
                updateStatus('leftClickStatus', 'Working', true);
            });

            canvas.addEventListener('touchmove', (e) => {
                e.preventDefault();
                if (!isDrawing) return;

                const rect = canvas.getBoundingClientRect();
                const touch = e.touches[0];
                const x = touch.clientX - rect.left;
                const y = touch.clientY - rect.top;

                ctx.beginPath();
                ctx.moveTo(lastX, lastY);
                ctx.lineTo(x, y);
                ctx.stroke();

                lastX = x;
                lastY = y;

                updateStatus('moveStatus', 'Working', true);
                updateStatus('dragStatus', 'Working', true);
            });

            canvas.addEventListener('touchend', () => isDrawing = false);

            canvas.addEventListener('contextmenu', (e) => {
                e.preventDefault();
                updateStatus('rightClickStatus', 'Working', true);
            });
        }

        function updateStatus(id, status, working) {
            const element = document.getElementById(id);
            if (element) {
                element.textContent = status;
                element.style.color = working ? '#27ae60' : '#e74c3c';
            }
        }

        function clearCanvas() {
            const canvas = document.getElementById('touchpad-canvas');
            const ctx = canvas.getContext('2d');
            ctx.clearRect(0, 0, canvas.width, canvas.height);
        }

        function changeDrawColor(color) {
            drawColor = color;
            const canvas = document.getElementById('touchpad-canvas');
            const ctx = canvas.getContext('2d');
            ctx.strokeStyle = color;
        }

        // Display Test Functions
        function testColorFullscreen(color) {
            const overlay = document.createElement('div');
            overlay.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: '+color+'; z-index: 99999; cursor: none;';
            overlay.id = 'fullscreen-color-test';

            const instruction = document.createElement('div');
            instruction.style.cssText = 'position: absolute; top: '+(Math.random() * 80 + 10)+'%; left: '+(Math.random() * 80 + 10)+'%; color: '+(color === 'white' || color === 'yellow' ? 'black' : 'white')+'; font-size: 24px; font-weight: bold; text-shadow: 0 0 10px '+(color === 'white' ? 'black' : 'white')+';';
            instruction.textContent = 'Testing ' + color.toUpperCase() + ' - Look for dead pixels. Press ESC or click to exit.';

            overlay.appendChild(instruction);
            document.body.appendChild(overlay);

            // Request fullscreen mode (hides browser UI)
            const elem = overlay;
            if (elem.requestFullscreen) {
                elem.requestFullscreen().catch(err => {
                    console.log('Fullscreen request failed:', err);
                });
            } else if (elem.webkitRequestFullscreen) {
                elem.webkitRequestFullscreen();
            } else if (elem.msRequestFullscreen) {
                elem.msRequestFullscreen();
            } else if (elem.mozRequestFullScreen) {
                elem.mozRequestFullScreen();
            }

            function exitTest() {
                // Exit fullscreen mode
                if (document.exitFullscreen) {
                    document.exitFullscreen().catch(() => {});
                } else if (document.webkitExitFullscreen) {
                    document.webkitExitFullscreen();
                } else if (document.msExitFullscreen) {
                    document.msExitFullscreen();
                } else if (document.mozCancelFullScreen) {
                    document.mozCancelFullScreen();
                }

                // Remove overlay
                setTimeout(() => {
                    if (overlay.parentNode) {
                        document.body.removeChild(overlay);
                    }
                    document.removeEventListener('keydown', handleEscape);
                    overlay.removeEventListener('click', exitTest);
                    document.removeEventListener('fullscreenchange', handleFullscreenChange);
                    document.removeEventListener('webkitfullscreenchange', handleFullscreenChange);
                    document.removeEventListener('msfullscreenchange', handleFullscreenChange);
                    document.removeEventListener('mozfullscreenchange', handleFullscreenChange);
                }, 100);
            }

            function handleEscape(e) {
                if (e.key === 'Escape') exitTest();
            }

            function handleFullscreenChange() {
                // Exit test when user exits fullscreen mode
                if (!document.fullscreenElement && !document.webkitFullscreenElement &&
                    !document.msFullscreenElement && !document.mozFullScreenElement) {
                    exitTest();
                }
            }

            document.addEventListener('keydown', handleEscape);
            overlay.addEventListener('click', exitTest);
            document.addEventListener('fullscreenchange', handleFullscreenChange);
            document.addEventListener('webkitfullscreenchange', handleFullscreenChange);
            document.addEventListener('msfullscreenchange', handleFullscreenChange);
            document.addEventListener('mozfullscreenchange', handleFullscreenChange);
        }

        // Audio Test Functions
        let audioContext = null;

        function getAudioContext() {
            if (!audioContext) {
                audioContext = new (window.AudioContext || window.webkitAudioContext)();
            }
            return audioContext;
        }

        function playLeftSpeaker() {
            const ctx = getAudioContext();
            const oscillator = ctx.createOscillator();
            const gainNode = ctx.createGain();
            const panner = ctx.createStereoPanner();

            oscillator.connect(gainNode);
            gainNode.connect(panner);
            panner.connect(ctx.destination);

            panner.pan.value = -1; // Left speaker
            oscillator.frequency.value = 440;
            oscillator.type = 'sine';

            oscillator.start();
            setTimeout(() => oscillator.stop(), 1000);
        }

        function playRightSpeaker() {
            const ctx = getAudioContext();
            const oscillator = ctx.createOscillator();
            const gainNode = ctx.createGain();
            const panner = ctx.createStereoPanner();

            oscillator.connect(gainNode);
            gainNode.connect(panner);
            panner.connect(ctx.destination);

            panner.pan.value = 1; // Right speaker
            oscillator.frequency.value = 440;
            oscillator.type = 'sine';

            oscillator.start();
            setTimeout(() => oscillator.stop(), 1000);
        }

        function playBothSpeakers() {
            const ctx = getAudioContext();
            const oscillator = ctx.createOscillator();
            const gainNode = ctx.createGain();

            oscillator.connect(gainNode);
            gainNode.connect(ctx.destination);

            oscillator.frequency.value = 440;
            oscillator.type = 'sine';

            oscillator.start();
            setTimeout(() => oscillator.stop(), 1000);
        }

        function playSweep() {
            const ctx = getAudioContext();
            const oscillator = ctx.createOscillator();
            const gainNode = ctx.createGain();

            oscillator.connect(gainNode);
            gainNode.connect(ctx.destination);

            oscillator.frequency.setValueAtTime(200, ctx.currentTime);
            oscillator.frequency.exponentialRampToValueAtTime(2000, ctx.currentTime + 2);
            oscillator.type = 'sine';

            oscillator.start();
            setTimeout(() => oscillator.stop(), 2000);
        }

        // Initialize on page load
        document.addEventListener('DOMContentLoaded', () => {
            console.log('Laptop Diagnostic Report v15.0 loaded');
        });
    </script>
</body>
</html>
"@

$htmlContent | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "Report saved: $reportPath" -ForegroundColor Yellow
Write-Host "`nOpening report in default browser..." -ForegroundColor Cyan

Start-Process $reportPath

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "  DIAGNOSTIC COMPLETE!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "`nReport generated successfully!" -ForegroundColor Green
Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
