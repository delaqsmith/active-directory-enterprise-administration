# Create-AdminFGPP.ps1
# Creates a Fine-Grained Password Policy for privileged admin accounts

$domain = (Get-ADDomain).DistinguishedName
$contosoPath = "OU=Contoso,$domain"
$adminPath = "OU=Admin Accounts,$contosoPath"
$groupsPath = "OU=Groups,$contosoPath"

# Step 1: Create the privileged admins group
New-ADGroup -Name "GG-PrivilegedAdmins" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path $groupsPath `
    -Description "Privileged administrator accounts subject to stricter password policy"
Write-Host "Created group: GG-PrivilegedAdmins" -ForegroundColor Green

# Step 2: Create an admin user account in the Admin Accounts OU
$adminPassword = ConvertTo-SecureString "Adm!nP@ss2024Str0ng" -AsPlainText -Force
New-ADUser -Name "Admin - Alice Johnson" `
    -SamAccountName "adm.ajohnson" `
    -UserPrincipalName "adm.ajohnson@$((Get-ADDomain).DNSRoot)" `
    -GivenName "Alice" `
    -Surname "Johnson" `
    -DisplayName "Admin - Alice Johnson" `
    -Description "Privileged admin account for Alice Johnson" `
    -Path $adminPath `
    -AccountPassword $adminPassword `
    -Enabled $true `
    -ChangePasswordAtLogon $true
Write-Host "Created admin account: adm.ajohnson" -ForegroundColor Green

# Add admin account to the privileged group
Add-ADGroupMember -Identity "GG-PrivilegedAdmins" -Members "adm.ajohnson"
Write-Host "Added adm.ajohnson to GG-PrivilegedAdmins" -ForegroundColor Green

# Step 3: Create the Fine-Grained Password Policy
New-ADFineGrainedPasswordPolicy -Name "AdminsPSO" `
    -Precedence 10 `
    -Description "Strict password policy for privileged administrator accounts" `
    -DisplayName "Admins Password Policy" `
    -MinPasswordLength 16 `
    -ComplexityEnabled $true `
    -MaxPasswordAge "30.00:00:00" `
    -MinPasswordAge "1.00:00:00" `
    -PasswordHistoryCount 24 `
    -LockoutThreshold 3 `
    -LockoutDuration "0.01:00:00" `
    -LockoutObservationWindow "0.01:00:00" `
    -ReversibleEncryptionEnabled $false
Write-Host "Created Fine-Grained Password Policy: AdminsPSO" -ForegroundColor Green

# Step 4: Apply the FGPP to the admin group
Add-ADFineGrainedPasswordPolicySubject -Identity "AdminsPSO" -Subjects "GG-PrivilegedAdmins"
Write-Host "Applied AdminsPSO to GG-PrivilegedAdmins" -ForegroundColor Green

# Step 5: Verify
Write-Host "`n--- Verification ---" -ForegroundColor Cyan
Write-Host "`nFGPP Settings:" -ForegroundColor Cyan
Get-ADFineGrainedPasswordPolicy -Identity "AdminsPSO" | Format-List Name, Precedence, MinPasswordLength, MaxPasswordAge, PasswordHistoryCount, LockoutThreshold, ComplexityEnabled

Write-Host "FGPP Subjects:" -ForegroundColor Cyan
Get-ADFineGrainedPasswordPolicySubject -Identity "AdminsPSO" | Format-Table Name, ObjectClass, DistinguishedName

Write-Host "`nResultant policy for adm.ajohnson:" -ForegroundColor Cyan
Get-ADUserResultantPasswordPolicy -Identity "adm.ajohnson" | Format-List Name, Precedence, MinPasswordLength, MaxPasswordAge

