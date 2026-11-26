# Create-OUStructure.ps1
# Creates the enterprise OU hierarchy for Contoso Corp

$domain = (Get-ADDomain).DistinguishedName

# Top-level OU
New-ADOrganizationalUnit -Name "Contoso" -Path $domain -ProtectedFromAccidentalDeletion $true

$contosoPath = "OU=Contoso,$domain"

# Second-level OUs
New-ADOrganizationalUnit -Name "Users" -Path $contosoPath -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Computers" -Path $contosoPath -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Groups" -Path $contosoPath -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Admin Accounts" -Path $contosoPath -ProtectedFromAccidentalDeletion $true

# Department OUs under Users
$usersPath = "OU=Users,$contosoPath"
New-ADOrganizationalUnit -Name "IT" -Path $usersPath -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "HR" -Path $usersPath -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Finance" -Path $usersPath -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Sales" -Path $usersPath -ProtectedFromAccidentalDeletion $true

# Computer sub-OUs
$computersPath = "OU=Computers,$contosoPath"
New-ADOrganizationalUnit -Name "Workstations" -Path $computersPath -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Servers" -Path $computersPath -ProtectedFromAccidentalDeletion $true

Write-Host "OU structure created successfully." -ForegroundColor Green
Get-ADOrganizationalUnit -Filter * -SearchBase $contosoPath | Format-Table Name, DistinguishedName

