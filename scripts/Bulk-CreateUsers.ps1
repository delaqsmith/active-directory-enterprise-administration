# Bulk-CreateUsers.ps1
# Creates AD users from a CSV file and places them in department OUs

$domain = (Get-ADDomain).DistinguishedName
$contosoPath = "OU=Contoso,$domain"
$usersPath = "OU=Users,$contosoPath"
$domainSuffix = (Get-ADDomain).DNSRoot
$defaultPassword = ConvertTo-SecureString "P@ssw0rd2024!" -AsPlainText -Force

$csvPath = "C:\Scripts\users.csv"
$logPath = "C:\Scripts\user-creation-log.csv"
$results = @()

$users = Import-Csv -Path $csvPath

foreach ($user in $users) {
    $ouPath = "OU=$($user.Department),$usersPath"
    $displayName = "$($user.FirstName) $($user.LastName)"
    $upn = "$($user.Username)@$domainSuffix"

    try {
        New-ADUser `
            -Name $displayName `
            -GivenName $user.FirstName `
            -Surname $user.LastName `
            -SamAccountName $user.Username `
            -UserPrincipalName $upn `
            -DisplayName $displayName `
            -Department $user.Department `
            -Title $user.Title `
            -Path $ouPath `
            -AccountPassword $defaultPassword `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        $results += [PSCustomObject]@{
            Username = $user.Username
            DisplayName = $displayName
            Department = $user.Department
            OU = $ouPath
            Status = "Success"
            Error = ""
        }
        Write-Host "Created: $displayName ($($user.Username))" -ForegroundColor Green
    }
    catch {
        $results += [PSCustomObject]@{
            Username = $user.Username
            DisplayName = $displayName
            Department = $user.Department
            OU = $ouPath
            Status = "Failed"
            Error = $_.Exception.Message
        }
        Write-Host "Failed: $displayName - $($_.Exception.Message)" -ForegroundColor Red
    }
}

$results | Export-Csv -Path $logPath -NoTypeInformation
Write-Host "`nUser creation complete. Log saved to: $logPath" -ForegroundColor Cyan
Write-Host "Total: $($results.Count) | Success: $(($results | Where-Object Status -eq 'Success').Count) | Failed: $(($results | Where-Object Status -eq 'Failed').Count)"