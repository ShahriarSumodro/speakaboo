#!/usr/bin/env pwsh
# verify_all.ps1 — Run all checks for the Speakaboo project.
# Exit code 0 = all pass, 1 = at least one failure.

$ErrorActionPreference = "Continue"
$failed = @()
$passed = @()
$python = "C:\Users\User\AppData\Local\Python\bin\python.exe"
$repoRoot = Split-Path -Parent $PSScriptRoot

Write-Host "`n========== VERIFY ALL ==========" -ForegroundColor Cyan

# --- 1. Backend pytest ---
Write-Host "`n[1/4] Backend pytest..." -ForegroundColor Yellow
$backendDir = Join-Path $repoRoot "backend"
$env:TEST_MODE = "true"
$proc = Start-Process -FilePath $python -ArgumentList "-m", "pytest", "tests/", "-x", "-q", "--tb=short" `
    -WorkingDirectory $backendDir -NoNewWindow -PassThru -Wait
if ($proc.ExitCode -eq 0) {
    $passed += "backend-pytest"
    Write-Host "  PASS: backend pytest" -ForegroundColor Green
} else {
    $failed += "backend-pytest"
    Write-Host "  FAIL: backend pytest (exit $($proc.ExitCode))" -ForegroundColor Red
}

# --- 2. Dart analyze ---
Write-Host "`n[2/4] Dart analyze..." -ForegroundColor Yellow
$appDir = Join-Path $repoRoot "app"
Push-Location $appDir
try {
    $analyzeOutput = & dart analyze lib test 2>&1
    $analyzeExit = $LASTEXITCODE
    if ($analyzeExit -eq 0) {
        $passed += "dart-analyze"
        Write-Host "  PASS: dart analyze" -ForegroundColor Green
    } else {
        $failed += "dart-analyze"
        Write-Host "  FAIL: dart analyze (exit $analyzeExit)" -ForegroundColor Red
        Write-Host $analyzeOutput
    }
} finally {
    Pop-Location
}

# --- 3. Flutter test ---
Write-Host "`n[3/4] Flutter test..." -ForegroundColor Yellow
Push-Location $appDir
try {
    $testOutput = & flutter test --no-pub 2>&1
    $testExit = $LASTEXITCODE
    if ($testExit -eq 0) {
        $passed += "flutter-test"
        Write-Host "  PASS: flutter test" -ForegroundColor Green
    } else {
        $failed += "flutter-test"
        Write-Host "  FAIL: flutter test (exit $testExit)" -ForegroundColor Red
        Write-Host $testOutput
    }
} finally {
    Pop-Location
}

# --- 4. check_docs.py (Phase 5, may not exist yet) ---
$checkDocs = Join-Path $repoRoot "scripts" "check_docs.py"
if (Test-Path $checkDocs) {
    Write-Host "`n[4/4] check_docs.py..." -ForegroundColor Yellow
    $proc2 = Start-Process -FilePath $python -ArgumentList $checkDocs `
        -WorkingDirectory $repoRoot -NoNewWindow -PassThru -Wait
    if ($proc2.ExitCode -eq 0) {
        $passed += "check-docs"
        Write-Host "  PASS: check_docs.py" -ForegroundColor Green
    } else {
        $failed += "check-docs"
        Write-Host "  FAIL: check_docs.py (exit $($proc2.ExitCode))" -ForegroundColor Red
    }
} else {
    Write-Host "`n[4/4] check_docs.py... SKIP (not yet created)" -ForegroundColor DarkGray
}

# --- Summary ---
Write-Host "`n========== SUMMARY ==========" -ForegroundColor Cyan
Write-Host "Passed: $($passed -join ', ')" -ForegroundColor Green
if ($failed.Count -gt 0) {
    Write-Host "Failed: $($failed -join ', ')" -ForegroundColor Red
    exit 1
} else {
    Write-Host "ALL CHECKS PASSED" -ForegroundColor Green
    exit 0
}
