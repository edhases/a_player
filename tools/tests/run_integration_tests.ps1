# Oxide Player Integration Test Runner
# 
# This script runs all integration tests and generates a report
# Usage: .\run_integration_tests.ps1 [-Device "device_id"] [-TestFile "test_name"] [-Verbose]

param(
    [string]$Device = "",
    [string]$TestFile = "",
    [switch]$Verbose = $false,
    [switch]$All = $false
)

$ErrorActionPreference = "Continue"

# Navigate to project root (2 levels up from tools/tests)
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ($ProjectRoot -eq "") {
    $ProjectRoot = Join-Path (Get-Location) "..\.."
}
Set-Location $ProjectRoot

$TestDir = "integration_test"
$ReportDir = "test_reports"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Create report directory
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir | Out-Null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Oxide Player Integration Test Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# List available tests
$TestFiles = @(
    "comprehensive_test.dart",
    "playback_test.dart",
    "navigation_test.dart",
    "localization_test.dart",
    "functional_protocol_test.dart"
)

Write-Host "Available test suites:" -ForegroundColor Yellow
$TestFiles | ForEach-Object { Write-Host "  - $_" }
Write-Host ""

# Determine which tests to run
$TestsToRun = @()
if ($All) {
    $TestsToRun = $TestFiles
} elseif ($TestFile -ne "") {
    if ($TestFile -like "*.dart") {
        $TestsToRun = @($TestFile)
    } else {
        $TestsToRun = @("${TestFile}.dart")
    }
} else {
    # Default: run comprehensive test
    $TestsToRun = @("comprehensive_test.dart")
}

Write-Host "Tests to run:" -ForegroundColor Green
$TestsToRun | ForEach-Object { Write-Host "  - $_" }
Write-Host ""

# Device selection
$DeviceArg = ""
if ($Device -ne "") {
    $DeviceArg = "-d $Device"
    Write-Host "Using device: $Device" -ForegroundColor Cyan
} else {
    Write-Host "Using default device" -ForegroundColor Cyan
}

# Run tests
$Results = @{}
$TotalTests = 0
$PassedTests = 0
$FailedTests = 0

foreach ($Test in $TestsToRun) {
    $TestPath = Join-Path $TestDir $Test
    
    if (-not (Test-Path $TestPath)) {
        Write-Host "Test file not found: $TestPath" -ForegroundColor Red
        continue
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "Running: $Test" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    
    $StartTime = Get-Date
    $ReportFile = Join-Path $ReportDir "$($Test -replace '\.dart$', '')_$Timestamp.log"
    
    # Build command
    $Cmd = "flutter test $TestPath $DeviceArg"
    if ($Verbose) {
        $Cmd += " --verbose"
    }
    
    Write-Host "Command: $Cmd" -ForegroundColor Gray
    Write-Host ""
    
    # Run and capture output
    $Output = Invoke-Expression "$Cmd 2>&1"
    $ExitCode = $LASTEXITCODE
    
    # Save output to report file
    $Output | Out-File -FilePath $ReportFile -Encoding UTF8
    
    $EndTime = Get-Date
    $Duration = ($EndTime - $StartTime).TotalSeconds
    
    # Parse results
    $Passed = $Output | Select-String -Pattern "\+\d+ -0:" -Quiet
    if ($null -eq $Passed) {
        $Passed = $ExitCode -eq 0
    }
    
    $Results[$Test] = @{
        Passed = $Passed
        Duration = [math]::Round($Duration, 2)
        ExitCode = $ExitCode
        ReportFile = $ReportFile
    }
    
    $TotalTests++
    if ($Passed) {
        $PassedTests++
        Write-Host "PASSED" -ForegroundColor Green -NoNewline
    } else {
        $FailedTests++
        Write-Host "FAILED" -ForegroundColor Red -NoNewline
    }
    Write-Host " (${Duration}s)" -ForegroundColor Gray
    
    # Show last few lines of output if failed
    if (-not $Passed) {
        Write-Host ""
        Write-Host "Last 20 lines of output:" -ForegroundColor Yellow
        $Output | Select-Object -Last 20 | ForEach-Object { Write-Host $_ }
    }
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total:  $TotalTests" -ForegroundColor White
Write-Host "Passed: $PassedTests" -ForegroundColor Green
Write-Host "Failed: $FailedTests" -ForegroundColor $(if ($FailedTests -gt 0) { "Red" } else { "Green" })
Write-Host ""

# Detailed results
Write-Host "Detailed Results:" -ForegroundColor Yellow
foreach ($Test in $Results.Keys) {
    $Result = $Results[$Test]
    $Status = if ($Result.Passed) { "[PASS]" } else { "[FAIL]" }
    $Color = if ($Result.Passed) { "Green" } else { "Red" }
    Write-Host "  $Status $Test - $($Result.Duration)s" -ForegroundColor $Color
    Write-Host "         Report: $($Result.ReportFile)" -ForegroundColor Gray
}

# Generate summary report
$SummaryFile = Join-Path $ReportDir "summary_$Timestamp.md"
$SummaryContent = @"
# Oxide Player Integration Test Report

**Date:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Device:** $(if ($Device -ne "") { $Device } else { "Default" })

## Summary

| Metric | Value |
|--------|-------|
| Total Tests | $TotalTests |
| Passed | $PassedTests |
| Failed | $FailedTests |
| Pass Rate | $([math]::Round(($PassedTests / [math]::Max($TotalTests, 1)) * 100, 1))% |

## Test Results

| Test Suite | Status | Duration |
|------------|--------|----------|
$(foreach ($Test in $Results.Keys) {
    $Result = $Results[$Test]
    $Status = if ($Result.Passed) { "✅ PASS" } else { "❌ FAIL" }
    "| $Test | $Status | $($Result.Duration)s |`n"
})

## Test Files Run

$(foreach ($Test in $TestsToRun) {
    "- ``$Test```n"
})

## Report Files

$(foreach ($Test in $Results.Keys) {
    $Result = $Results[$Test]
    "- [$Test]($($Result.ReportFile))`n"
})
"@

$SummaryContent | Out-File -FilePath $SummaryFile -Encoding UTF8
Write-Host ""
Write-Host "Summary report: $SummaryFile" -ForegroundColor Cyan

# Exit with appropriate code
if ($FailedTests -gt 0) {
    exit 1
} else {
    exit 0
}
