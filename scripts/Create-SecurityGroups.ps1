# Create-SecurityGroups.ps1
# Creates security groups following the AGDLP pattern and assigns users

$domain = (Get-ADDomain).DistinguishedName
$contosoPath = "OU=Contoso,$domain"
$groupsPath = "OU=Groups,$contosoPath"
$usersPath = "OU=Users,$contosoPath"

# Create Global groups for each department
$departments = @("IT", "HR", "Finance", "Sales")
foreach ($dept in $departments) {
    New-ADGroup -Name "GG-$dept-Staff" `
        -GroupScope Global `
        -GroupCategory Security `
        -Path $groupsPath `
        -Description "Global group for $dept department staff"
    Write-Host "Created Global group: GG-$dept-Staff" -ForegroundColor Green
}

# Create Helpdesk group
New-ADGroup -Name "GG-Helpdesk" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path $groupsPath `
    -Description "Helpdesk staff with delegated password reset permissions"
Write-Host "Created Global group: GG-Helpdesk" -ForegroundColor Green

# Create Domain Local groups for resource access
$resources = @(
    @{Name="DL-FileShare-IT-ReadWrite"; Desc="Read/Write access to IT file share"},
    @{Name="DL-FileShare-HR-Read"; Desc="Read access to HR file share"},
    @{Name="DL-FileShare-Finance-ReadWrite"; Desc="Read/Write access to Finance file share"},
    @{Name="DL-FileShare-Sales-Read"; Desc="Read access to Sales file share"}
)

foreach ($res in $resources) {
    New-ADGroup -Name $res.Name `
        -GroupScope DomainLocal `
        -GroupCategory Security `
        -Path $groupsPath `
        -Description $res.Desc
    Write-Host "Created Domain Local group: $($res.Name)" -ForegroundColor Green
}

# Add users to their department Global groups
foreach ($dept in $departments) {
    $deptUsers = Get-ADUser -Filter * -SearchBase "OU=$dept,$usersPath"
    foreach ($user in $deptUsers) {
        Add-ADGroupMember -Identity "GG-$dept-Staff" -Members $user
    }
    Write-Host "Added $($deptUsers.Count) users to GG-$dept-Staff" -ForegroundColor Cyan
}

# Add helpdesk user to GG-Helpdesk
Add-ADGroupMember -Identity "GG-Helpdesk" -Members "dbrown"
Write-Host "Added dbrown to GG-Helpdesk" -ForegroundColor Cyan

# Nest Global groups into Domain Local groups (AGDLP)
Add-ADGroupMember -Identity "DL-FileShare-IT-ReadWrite" -Members "GG-IT-Staff"
Add-ADGroupMember -Identity "DL-FileShare-HR-Read" -Members "GG-HR-Staff"
Add-ADGroupMember -Identity "DL-FileShare-Finance-ReadWrite" -Members "GG-Finance-Staff"
Add-ADGroupMember -Identity "DL-FileShare-Sales-Read" -Members "GG-Sales-Staff"

Write-Host "`nAGDLP nesting complete." -ForegroundColor Green
Write-Host "Verifying nesting..."
foreach ($dept in $departments) {
    $members = Get-ADGroupMember -Identity "GG-$dept-Staff"
    Write-Host "GG-$dept-Staff has $($members.Count) members" -ForegroundColor Cyan
}

