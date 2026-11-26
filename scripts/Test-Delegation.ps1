# Test-Delegation.ps1
# Run this script as the helpdesk user to verify delegated permissions
# Usage: runas /user:yourdomain\dbrown powershell
# Then run this script from that session

$domain = (Get-ADDomain).DistinguishedName
$testUser = "ajohnson"

Write-Host "Testing delegation as: $env:USERNAME" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Test 1: Reset a password (should succeed)
Write-Host "`nTest 1: Resetting password for $testUser..."
try {
    Set-ADAccountPassword -Identity $testUser -Reset -NewPassword (ConvertTo-SecureString "NewP@ss2024!" -AsPlainText -Force)
    Write-Host "SUCCESS: Password reset completed." -ForegroundColor Green
}
catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Unlock an account (should succeed)
Write-Host "`nTest 2: Unlocking account $testUser..."
try {
    Unlock-ADAccount -Identity $testUser
    Write-Host "SUCCESS: Account unlocked." -ForegroundColor Green
}
catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Try to create a user (should fail - not delegated)
Write-Host "`nTest 3: Attempting to create a new user (should fail)..."
try {
    New-ADUser -Name "Test Unauthorized" -SamAccountName "tunauth" -Path "OU=IT,OU=Users,OU=Contoso,$domain" -Enabled $false
    Write-Host "UNEXPECTED SUCCESS: This should have been denied!" -ForegroundColor Yellow
}
catch {
    Write-Host "EXPECTED FAILURE: Access denied - delegation is working correctly." -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Delegation testing complete." -ForegroundColor Cyan

