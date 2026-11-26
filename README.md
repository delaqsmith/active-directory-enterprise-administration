# 🏢 Enterprise Active Directory Administration Lab

### Organizational Unit Design | PowerShell Automation | RBAC | Helpdesk Delegation | Privileged Account Security

## 📖 Project Overview

This project demonstrates the configuration and administration of a structured Active Directory environment designed to simulate enterprise identity and access management operations.

Using **Windows Server 2022, Active Directory Domain Services (AD DS), and PowerShell**, I developed an organizational framework for a fictional company to manage employee accounts, departmental access, administrative permissions, and privileged account security.

The lab focuses on five core responsibilities commonly performed by systems administrators and IT support professionals:

- Designing an Organizational Unit (OU) hierarchy for centralized identity management.
- Automating employee account provisioning using PowerShell and CSV data.
- Implementing role-based access control (RBAC) using Active Directory security groups.
- Delegating helpdesk administrative tasks without granting Domain Administrator privileges.
- Applying Fine-Grained Password Policies (FGPPs) to privileged accounts.

The project emphasizes **automation, least-privilege access, administrative delegation, and identity security**.

---

## 🎯 Project Objectives

The primary objective was to build an enterprise-style Active Directory environment that supports efficient account administration while maintaining appropriate security boundaries.

Specific objectives included:

1. Design a scalable OU hierarchy for users, computers, security groups, and administrative accounts.
2. Provision 15 employee accounts across four departments using PowerShell automation.
3. Implement RBAC using the Accounts → Global Groups → Domain Local Groups → Permissions (AGDLP) model.
4. Configure delegated helpdesk permissions for routine account-management tasks.
5. Validate administrative restrictions using a standard, non-administrator account.
6. Configure stricter password and account-lockout requirements for privileged identities.

---

## 🛠️ Technologies and Tools

| Technology | Purpose |
|---|---|
| Windows Server 2022 | Server operating system |
| Active Directory Domain Services | Centralized identity and directory management |
| Oracle VirtualBox | Virtual machine hosting and network confirguration |
| Windows PowerShell | Administrative automation and scripting |
| Active Directory PowerShell Module | Management of AD users, groups, OUs, and policies |
| Active Directory Users and Computers (ADUC) | GUI-based directory administration |
| Active Directory Administrative Center | Password policy management and verification |
| CSV | Structured input for bulk user provisioning |
| Group Policy | OU-based policy scoping concepts |
| Fine-Grained Password Policies | Privileged account password and lockout controls |

---

## 🏗️ Lab Environment

The project was completed in a virtualized Windows Server environment.

### Infrastructure

| Component | Configuration |
|---|---|
| Virtualization Platform | Oracle VirtualBox |
| Domain Controller | Windows Server 2022 |
| Directory Service | Active Directory Domain Services |
| Domain | Existing lab domain |
| Organization | Contoso Corp (fictional) |
| Departments | IT, HR, Finance, Sales |
| Employee Accounts | 15 |
| Administrative Account | 1 dedicated privileged identity |
| Management Interface | PowerShell and ADUC |

### Prerequisites

Before beginning the project, the following environment was required:

- A Windows Server 2022 virtual machine.
- Active Directory Domain Services installed.
- Server promoted to a Domain Controller.
- An operational Active Directory domain.
- Administrative credentials for configuring directory objects.
- Active Directory PowerShell module available.
- A `C:\Scripts` directory for storing automation files.

### Active Directory Architecture

The OU structure separates directory objects by administrative function, enabling more predictable delegation and Group Policy scoping.

```text
Active Directory Domain
│
└── OU=Contoso
    │
    ├── OU=Users
    │ ├── OU=IT
    │ ├── OU=HR
    │ ├── OU=Finance
    │ └── OU=Sales
    │
    ├── OU=Computers
    │ ├── OU=Workstations
    │ └── OU=Servers
    │
    ├── OU=Groups
    │
    └── OU=Admin Accounts
```

This structure provides separate administrative boundaries for standard users, computer objects, security groups, and privileged accounts.

---

# ⚙️ Implementation

## Phase 1: Design and Build the Organizational Unit Structure

### Objective

Create a structured Active Directory OU hierarchy that supports departmental organization, administrative delegation, and Group Policy management.

### 1.1 Design the OU Hierarchy

I designed a top-level OU named `Contoso` containing four primary branches:

| OU | Purpose |
|---|---|
| Users | Stores employee accounts organized by department |
| Computers | Separates workstation and server computer objects |
| Groups | Centralizes security group management |
| Admin Accounts | Separates privileged identities from standard user accounts |

The Users OU contains four departmental sub-OUs: IT, HR, Finance, and Sales.

The Computers OU contains separate Workstations and Servers sub-OUs.

This design supports applying different policies and administrative permissions to different object categories.

### 1.2 Automate OU Creation with PowerShell

Rather than manually creating each OU through Active Directory Users and Computers, I developed a PowerShell script to automate the hierarchy.

**Script:** `scripts/Create-OUStructure.ps1`

The script dynamically retrieves the domain's Distinguished Name:

```powershell
$domain = (Get-ADDomain).DistinguishedName
```

It then creates the top-level organizational unit:

```powershell
New-ADOrganizationalUnit `
    -Name "Contoso" `
    -Path $domain `
    -ProtectedFromAccidentalDeletion $true
```

The script creates the remaining organizational units using the appropriate parent OU paths.

For example:

```powershell
$contosoPath = "OU=Contoso,$domain"

New-ADOrganizationalUnit `
    -Name "Users" `
    -Path $contosoPath `
    -ProtectedFromAccidentalDeletion $true
```

All OUs were configured with accidental deletion protection to reduce the risk of unintended administrative changes.

### 1.3 Validate the OU Structure

I used PowerShell to query the newly created organizational units:

```powershell
Get-ADOrganizationalUnit `
    -Filter * `
    -SearchBase "OU=Contoso,$((Get-ADDomain).DistinguishedName)" |
    Format-Table Name, DistinguishedName
```

I also inspected the directory structure through Active Directory Users and Computers:

```powershell
dsa.msc
```

**Validation criteria:**

- The Contoso OU exists beneath the domain root.
- Users, Computers, Groups, and Admin Accounts exist as child OUs.
- All four department OUs exist beneath Users.
- Workstations and Servers exist beneath Computers.
- Accidental deletion protection is enabled.

<img width="742" height="453" alt="image" src="https://github.com/user-attachments/assets/7d41f049-c12f-4601-9f93-c98c51db243d" />


### Technical Significance

This phase demonstrates the ability to design and automate a structured directory environment.

Organizing objects by administrative requirements helps support:

- Granular Group Policy targeting.
- Department-specific account administration.
- Delegated management permissions.
- Separation of privileged and standard identities.
- Scalable directory administration.

**Important:** OU placement alone does not guarantee that a Group Policy applies to every object beneath it. Actual policy processing also depends on the GPO configuration, inheritance, security filtering, and other applicable settings.

---

## Phase 2: Automate Bulk User Provisioning

### Objective

Automate the creation of employee accounts from structured CSV data and place each account into its corresponding departmental OU.

### 2.1 Prepare Employee Data

I created a CSV file containing 15 fictional employee records distributed across four departments.

**File:** `data/users.csv`

Each record contains the following attributes:

| Attribute | Description |
|---|---|
| FirstName | Employee first name |
| LastName | Employee last name |
| Department | Assigned department |
| Title | Employee job title |
| Username | Active Directory logon name |

Example:

```csv
FirstName,LastName,Department,Title,Username
Alice,Johnson,IT,Systems Administrator,ajohnson
Bob,Smith,IT,Network Engineer,bsmith
Carol,Williams,IT,Security Analyst,cwilliams
David,Brown,IT,Helpdesk Technician,dbrown
Emma,Davis,HR,HR Manager,edavis
```

The complete dataset contains:

| Department | Accounts |
|---|---:|
| IT | 4 |
| HR | 3 |
| Finance | 4 |
| Sales | 4 |
| **Total** | **15** |

### 2.2 Develop the Bulk Provisioning Script

**Script:** `scripts/Bulk-CreateUsers.ps1`

The script imports employee records using:

```powershell
$users = Import-Csv -Path "C:\Scripts\users.csv"
```

For each record, the script constructs the appropriate OU path using the employee's department:

```powershell
$ouPath = "OU=$($user.Department),$usersPath"
```

It then provisions the account using `New-ADUser`.

Example:

```powershell
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
    -AccountPassword $initialPassword `
    -Enabled $true `
    -ChangePasswordAtLogon $true `
    -ErrorAction Stop
```

### Password Handling

The original lab used a shared demonstration password during account provisioning.

For the repository version, password handling should use a secure interactive prompt instead of embedding plaintext credentials in source code:

```powershell
$initialPassword = Read-Host `
    "Enter the temporary account password" `
    -AsSecureString
```

This prevents a plaintext password from being published directly in the GitHub repository.

For a production deployment, temporary credentials should be unique per user, securely delivered, and managed according to organizational password policies.

### 2.3 Implement Error Handling and Logging

The provisioning script uses `try/catch` blocks to handle individual account creation failures.

Example:

```powershell
try {
    New-ADUser @userParameters -ErrorAction Stop

    $status = "Success"
    $errorMessage = ""
}
catch {
    $status = "Failed"
    $errorMessage = $_.Exception.Message
}
```

The script records provisioning results and exports them to a CSV log.

**Output:** `user-creation-log.csv`

The log includes:

- Username
- Display name
- Department
- Target OU
- Provisioning status
- Error message, if applicable

This provides a basic audit trail for reviewing provisioning activity.

### 2.4 Verify User Creation

I used the following command to inspect accounts created beneath the Users OU:

```powershell
Get-ADUser `
    -Filter * `
    -SearchBase "OU=Users,OU=Contoso,$((Get-ADDomain).DistinguishedName)" `
    -Properties Department |
    Format-Table Name, Department, DistinguishedName
```

The expected distribution was:

| Department | Expected Users |
|---|---:|
| IT | 4 |
| HR | 3 |
| Finance | 4 |
| Sales | 4 |

I also used ADUC to inspect each department OU and verify the account placement.

<img width="371" height="152" alt="image" src="https://github.com/user-attachments/assets/b4493554-c985-4ea5-8937-706394b530f3" />


<img width="536" height="260" alt="image" src="https://github.com/user-attachments/assets/9c3266ea-c227-4811-b1de-f16eba88dfea" />


### Technical Significance

This phase demonstrates practical PowerShell automation for identity lifecycle management.

The same general approach can support:

- Employee onboarding.
- Department-based account placement.
- Standardized user attributes.
- Reduced manual administration.
- Repeatable provisioning workflows.
- Auditable account creation.

---

## Phase 3: Implement Role-Based Access Control

### Objective

Implement role-based security group management using the AGDLP model to separate user identities from resource permissions.

### 3.1 Understand the AGDLP Model

AGDLP stands for:

**Accounts → Global Groups → Domain Local Groups → Permissions**

This model separates users from resource-specific access assignments.

```text
User Accounts
     │
     ▼
Global Security Groups
     │
     ▼
Domain Local Security Groups
     │
     ▼
Resource Permissions
```

Global groups represent organizational roles or departments.

Domain Local groups represent access requirements associated with specific resources.

### 3.2 Create Department Security Groups

**Script:** `scripts/Create-SecurityGroups.ps1`

I created Global security groups for the four departments:

| Global Group | Purpose |
|---|---|
| GG-IT-Staff | IT employees |
| GG-HR-Staff | Human Resources employees |
| GG-Finance-Staff | Finance employees |
| GG-Sales-Staff | Sales employees |
| GG-Helpdesk | Delegated IT support staff |

Example:

```powershell
New-ADGroup `
    -Name "GG-IT-Staff" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path $groupsPath `
    -Description "Global group for IT department staff"
```

### 3.3 Create Resource Access Groups

I created Domain Local security groups representing departmental file access.

| Domain Local Group | Intended Access |
|---|---|
| DL-FileShare-IT-ReadWrite | IT file share read/write |
| DL-FileShare-HR-Read | HR file share read |
| DL-FileShare-Finance-ReadWrite | Finance file share read/write |
| DL-FileShare-Sales-Read | Sales file share read |

Example:

```powershell
New-ADGroup `
    -Name "DL-FileShare-IT-ReadWrite" `
    -GroupScope DomainLocal `
    -GroupCategory Security `
    -Path $groupsPath
```

### 3.4 Assign Users to Department Groups

The script queries each department OU and adds its users to the corresponding Global security group.

Example:

```powershell
$deptUsers = Get-ADUser `
    -Filter * `
    -SearchBase "OU=IT,$usersPath"

foreach ($user in $deptUsers) {
    Add-ADGroupMember `
        -Identity "GG-IT-Staff" `
        -Members $user
}
```

The helpdesk technician account was also assigned to the Helpdesk security group:

```powershell
Add-ADGroupMember `
    -Identity "GG-Helpdesk" `
    -Members "dbrown"
```

### 3.5 Configure AGDLP Group Nesting

I nested the departmental Global groups inside the corresponding Domain Local groups.

Example:

```powershell
Add-ADGroupMember `
    -Identity "DL-FileShare-IT-ReadWrite" `
    -Members "GG-IT-Staff"
```

The resulting membership structure is:

```text
ajohnson
   │
   ▼
GG-IT-Staff
   │
   ▼
DL-FileShare-IT-ReadWrite
   │
   ▼
Intended IT File Share Permissions
```

### Important Technical Clarification

Creating and nesting the security groups establishes the identity and authorization structure, but it does **not automatically grant file access**.

To complete the permissions stage of AGDLP, the Domain Local groups must also be assigned appropriate NTFS and, where applicable, SMB share permissions on the actual resources.

This lab demonstrates the security group creation and nesting components of AGDLP.

Actual file server permission assignment is a potential extension of the project.

### 3.6 Verify Group Membership

I verified the Domain Local group nesting:

```powershell
Get-ADGroupMember `
    -Identity "DL-FileShare-IT-ReadWrite"
```

I also inspected the IT Global group:

```powershell
Get-ADGroupMember `
    -Identity "GG-IT-Staff"
```

Expected members:

- Alice Johnson
- Bob Smith
- Carol Williams
- David Brown

To inspect recursive group membership:

```powershell
Get-ADGroupMember `
    -Identity "DL-FileShare-IT-ReadWrite" `
    -Recursive
```

This recursively expands nested membership to display the users associated with the resource group.

<img width="539" height="258" alt="image" src="https://github.com/user-attachments/assets/cefa361c-6169-42f8-a344-cb58a9d44858" />



### Technical Significance

This phase demonstrates the ability to:

- Organize access through security groups.
- Implement role-based identity management.
- Separate organizational roles from resource permissions.
- Simplify employee access administration.
- Apply least-privilege principles to directory group design.

---

## Phase 4: Delegate Administrative Control to Helpdesk

### Objective

Allow a non-administrator helpdesk technician to perform authorized account support tasks without granting Domain Administrator privileges.

### 4.1 Prepare the Helpdesk Security Group

I used the previously created `GG-Helpdesk` Global security group as the delegation target.

The fictional employee David Brown (`dbrown`) was assigned to this group.

I verified membership using:

```powershell
Get-ADGroupMember `
    -Identity "GG-Helpdesk" |
    Format-Table Name, SamAccountName
```

### 4.2 Configure Delegation in ADUC

I opened Active Directory Users and Computers:

```powershell
dsa.msc
```

I then navigated to:

```text
Contoso
└── Users
```

Using the **Delegation of Control Wizard**, I selected the `GG-Helpdesk` security group and configured the following delegated tasks:

- Reset user passwords and force password changes at next logon.
- Read all user information.

The delegation was applied to the Users OU, which contains the departmental user accounts.

This allows delegated permissions to be inherited by applicable user objects in the child OUs.

### Important Technical Clarification: Account Unlocking

Password reset permissions and account unlocking are separate administrative capabilities.

Delegating password reset rights does not necessarily grant permission to unlock locked accounts.

Unlocking typically requires permission to modify the relevant account lockout attribute, including `lockoutTime`.

Therefore, the helpdesk delegation must be reviewed to ensure the appropriate account-unlock permission is configured before treating account unlocking as an authorized operation.

### 4.3 Verify Delegated Permissions

I inspected the Users OU security settings through ADUC.

Navigation:

```text
Active Directory Users and Computers
    ↓
View → Advanced Features
    ↓
Contoso → Users
    ↓
Properties → Security → Advanced
```

The verification focused on confirming that the Helpdesk group had the intended delegated permissions.

<img width="538" height="260" alt="image" src="https://github.com/user-attachments/assets/81461948-b382-48d8-b4f5-2efd88c65888" />


### 4.4 Test Delegation Using a Non-Admin Account

**Script:** `scripts/Test-Delegation.ps1`

To validate least-privilege administration, I designed a test using the standard helpdesk account `dbrown`.

The test evaluates three administrative operations.

| Test | Action | Expected Result |
|---|---|---|
| 1 | Reset a standard user's password | Allowed |
| 2 | Unlock a locked account | Allowed only when unlock permissions are explicitly delegated |
| 3 | Create a new user account | Denied |

The test account should not be a member of Domain Admins or another privileged group that could invalidate the least-privilege test.

### Test 1: Password Reset

The first test attempts to reset a standard user's password.

```powershell
$newPassword = Read-Host `
    "Enter the temporary password for the test account" `
    -AsSecureString

Set-ADAccountPassword `
    -Identity "ajohnson" `
    -Reset `
    -NewPassword $newPassword `
    -ErrorAction Stop
```

**Expected result:** The operation succeeds because password reset rights were delegated to the Helpdesk group.

### Test 2: Account Unlock

The second test attempts to unlock a previously locked test account.

```powershell
Unlock-ADAccount `
    -Identity "ajohnson" `
    -ErrorAction Stop
```

**Expected result:** The operation succeeds only if the necessary unlock permissions were explicitly configured.

The account should be placed into a controlled locked-out state before testing so the result meaningfully demonstrates account-unlock functionality.

### Test 3: Unauthorized User Creation

The final test attempts an operation outside the Helpdesk group's delegated permissions.

```powershell
New-ADUser `
    -Name "Test Unauthorized" `
    -SamAccountName "tunauth" `
    -Path "OU=IT,OU=Users,OU=Contoso,$((Get-ADDomain).DistinguishedName)" `
    -Enabled $false `
    -ErrorAction Stop
```

**Expected result:** The operation is denied because the Helpdesk group was not granted permission to create user accounts.

### 4.5 Validate the Security Boundary

The purpose of these tests is to confirm that the helpdesk account can perform authorized support tasks without receiving broader administrative permissions.

A valid least-privilege test requires:

1. Running the commands under the actual helpdesk account.
2. Confirming the account's group memberships.
3. Testing against accounts within the delegated OU scope.
4. Verifying the allowed operations succeed.
5. Verifying unauthorized operations fail with the expected permission error.
6. Recording actual command output as supporting evidence.

A generic script exception should not automatically be interpreted as proof of access denial. The specific error must be inspected.

### Technical Significance

This phase demonstrates the principle of least privilege through delegated Active Directory administration.

It also highlights the importance of validating security controls rather than assuming permissions are correctly configured.

---

## Phase 5: Implement Fine-Grained Password Policies

### Objective

Configure stricter password and account-lockout requirements for designated privileged accounts using Active Directory Fine-Grained Password Policies.

### 5.1 Create a Privileged Security Group

**Script:** `scripts/Create-AdminFGPP.ps1`

I created a Global security group named:

```text
GG-PrivilegedAdmins
```

Example:

```powershell
New-ADGroup `
    -Name "GG-PrivilegedAdmins" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path $groupsPath `
    -Description "Privileged accounts subject to stricter password requirements"
```

This group serves as the target for the Fine-Grained Password Policy.

### 5.2 Create a Dedicated Administrative Account

I created a separate administrative identity for Alice Johnson.

| Account | Purpose |
|---|---|
| ajohnson | Standard employee account |
| adm.ajohnson | Dedicated privileged identity |

The administrative identity was placed in the Admin Accounts OU.

Example:

```powershell
$adminPassword = Read-Host `
    "Enter the initial admin account password" `
    -AsSecureString

New-ADUser `
    -Name "Admin - Alice Johnson" `
    -SamAccountName "adm.ajohnson" `
    -UserPrincipalName "adm.ajohnson@$((Get-ADDomain).DNSRoot)" `
    -GivenName "Alice" `
    -Surname "Johnson" `
    -DisplayName "Admin - Alice Johnson" `
    -Path $adminPath `
    -AccountPassword $adminPassword `
    -Enabled $true `
    -ChangePasswordAtLogon $true `
    -ErrorAction Stop
```

I then added the account to the privileged security group:

```powershell
Add-ADGroupMember `
    -Identity "GG-PrivilegedAdmins" `
    -Members "adm.ajohnson"
```

### Important Technical Clarification

Creating a separate administrative account and placing it into `GG-PrivilegedAdmins` does not automatically grant Domain Administrator privileges.

The group in this lab is used to scope password policy requirements.

Any actual administrative rights must be granted separately through appropriate role assignments or delegated permissions.

This separation prevents password policy group membership from being confused with administrative authorization.

### 5.3 Configure the Fine-Grained Password Policy

I created a Fine-Grained Password Policy named `AdminsPSO`.

The policy was designed to enforce stronger requirements on accounts assigned to the privileged security group.

| Setting | Configuration |
|---|---|
| Policy Name | AdminsPSO |
| Precedence | 10 |
| Minimum Password Length | 16 characters |
| Password Complexity | Enabled |
| Maximum Password Age | 30 days |
| Minimum Password Age | 1 day |
| Password History | 24 passwords |
| Account Lockout Threshold | 3 failed attempts |
| Account Lockout Duration | 1 hour |
| Lockout Observation Window | 1 hour |
| Reversible Encryption | Disabled |

The policy was created using:

```powershell
New-ADFineGrainedPasswordPolicy `
    -Name "AdminsPSO" `
    -Precedence 10 `
    -Description "Password policy for privileged accounts" `
    -DisplayName "Admins Password Policy" `
    -MinPasswordLength 16 `
    -ComplexityEnabled $true `
    -MaxPasswordAge "30.00:00:00" `
    -MinPasswordAge "1.00:00:00" `
    -PasswordHistoryCount 24 `
    -LockoutThreshold 3 `
    -LockoutDuration "0.01:00:00" `
    -LockoutObservationWindow "0.01:00:00" `
    -ReversibleEncryptionEnabled $false `
    -ErrorAction Stop
```

These settings represent the lab's chosen security configuration rather than a universal production baseline.

In particular, password expiration and lockout thresholds should be evaluated against current organizational requirements and security guidance.

### 5.4 Apply the Password Policy

I assigned the FGPP to the privileged security group:

```powershell
Add-ADFineGrainedPasswordPolicySubject `
    -Identity "AdminsPSO" `
    -Subjects "GG-PrivilegedAdmins"
```

Fine-Grained Password Policies can be assigned to individual users or Global security groups.

Unlike Group Policy Objects, FGPPs are not linked directly to Organizational Units.

### 5.5 Verify the Policy Configuration

I inspected the password policy using:

```powershell
Get-ADFineGrainedPasswordPolicy `
    -Identity "AdminsPSO" |
    Format-List Name, Precedence, MinPasswordLength, MaxPasswordAge, PasswordHistoryCount, LockoutThreshold
```

I verified the assigned policy subject:

```powershell
Get-ADFineGrainedPasswordPolicySubject `
    -Identity "AdminsPSO"
```

Finally, I checked the resultant password policy for the administrative account:

```powershell
Get-ADUserResultantPasswordPolicy `
    -Identity "adm.ajohnson" |
    Format-List Name, Precedence, MinPasswordLength, MaxPasswordAge
```

**Expected result:**

```text
Name : AdminsPSO
Precedence : 10
MinPasswordLength : 16
MaxPasswordAge : 30.00:00:00
```

This verification confirms which Fine-Grained Password Policy applies to the account.

The password used during account creation should also satisfy the intended policy, and password enforcement should be tested separately if required.

<img width="461" height="307" alt="image" src="https://github.com/user-attachments/assets/ce0b8dff-fd90-42dd-b91e-265ca0d0fb9c" />


### Technical Significance

This phase demonstrates:

- Privileged identity separation.
- Group-based password policy targeting.
- Password and account-lockout configuration.
- Fine-Grained Password Policy administration.
- Verification of effective security settings.

---

# 🔍 Testing and Validation Summary

The following table summarizes the validation activities associated with the five implementation phases.

| Phase | Validation Activity | Expected Outcome |
|---|---|---|
| OU Design | Query OU hierarchy | All required OUs exist |
| User Provisioning | Query department accounts | 15 accounts in the correct OUs |
| RBAC | Inspect Global group membership | Users assigned to correct groups |
| AGDLP | Inspect Domain Local group membership | Department Global groups nested correctly |
| Helpdesk Delegation | Test password reset | Authorized operation succeeds |
| Helpdesk Delegation | Test account unlock | Succeeds when unlock rights are configured |
| Helpdesk Delegation | Attempt unauthorized user creation | Access denied |
| Password Policy | Query FGPP settings | Configured policy values returned |
| Password Policy | Query resultant policy | AdminsPSO applies to designated admin account |

**Evidence note:** These are the intended validation criteria. Actual pass/fail results should be recorded from the lab output and screenshots before publishing a final testing report.

---

# 🔐 Security Considerations

Several security principles guided the implementation of this project.

### Principle of Least Privilege

Helpdesk users receive only the administrative permissions required for their assigned responsibilities.

### Role-Based Access Control

Access management is organized through security groups rather than individual user permissions.

### Separation of Administrative Identities

Privileged accounts are separated from standard employee identities.

### Password Security

Fine-Grained Password Policies enforce additional password and lockout controls for designated accounts.

### Secure Automation

PowerShell scripts support repeatable administrative operations while reducing manual configuration errors.

### Credential Protection

Published scripts should not contain real passwords, API keys, domain credentials, or other sensitive information.

Temporary passwords should be collected or generated securely and managed according to organizational policy.

---

# 🧠 Skills Demonstrated

This project demonstrates practical experience in the following areas:

| Skill Area | Technical Skills |
|---|---|
| Active Directory Administration | OU design, user management, security groups |
| Identity and Access Management | Account provisioning, RBAC, privileged identity separation |
| PowerShell Automation | Scripting, loops, CSV imports, AD cmdlets |
| Access Control | AGDLP, security group nesting, delegated permissions |
| IT Support Operations | Password resets, account unlocking, helpdesk delegation |
| Security Administration | Least privilege, password policies, account lockout |
| Troubleshooting | Permission validation, error handling, verification |
| Documentation | Technical procedures, testing evidence, configuration records |

---

# 🚧 Challenges and Technical Considerations

## 1. Designing a Scalable OU Hierarchy

**Consideration:** Active Directory objects need to be organized in a way that supports administration, policy management, and future growth.

**Approach:** I separated users, computers, groups, and privileged accounts into dedicated OU branches.

## 2. Automating Account Placement

**Consideration:** Employee accounts must be created in the correct department OUs without requiring repetitive manual configuration.

**Approach:** I used CSV-driven PowerShell automation to dynamically construct OU paths from department attributes.

## 3. Separating Identity Groups from Resource Permissions

**Consideration:** Assigning resource permissions directly to individual accounts can become difficult to maintain.

**Approach:** I implemented Global and Domain Local security group nesting based on the AGDLP model.

## 4. Limiting Helpdesk Administrative Privileges

**Consideration:** Helpdesk technicians need to perform routine support tasks without receiving unrestricted domain access.

**Approach:** I scoped delegated permissions to the Users OU and designed positive and negative permission tests.

## 5. Applying Different Password Requirements

**Consideration:** Privileged identities may require password controls that differ from standard employee accounts.

**Approach:** I configured a Fine-Grained Password Policy targeting a dedicated Global security group.

---

# 🚀 Future Improvements

The lab provides a foundation for additional enterprise identity management projects.

Potential improvements include:

### 1. Implement Actual File Share Permissions

Deploy a Windows file server and assign NTFS and SMB share permissions to the Domain Local groups to complete the AGDLP access-control chain.

### 2. Configure Group Policy Objects

Create and test GPOs for:

- Workstation security baselines.
- Windows Defender Firewall settings.
- Screen lock requirements.
- Administrative restrictions.
- Department-specific configurations.

### 3. Expand User Lifecycle Automation

Develop additional PowerShell scripts for:

- Employee onboarding.
- Department transfers.
- Account disabling.
- Employee offboarding.
- Security group cleanup.

### 4. Add Active Directory Auditing

Enable relevant auditing and collect events associated with:

- User account creation and deletion.
- Password resets.
- Security group membership changes.
- Account lockouts.
- Privileged account activity.

### 5. Integrate Security Monitoring

Forward Windows Security Event Logs to a SIEM platform such as Splunk or Microsoft Sentinel.

This would allow identity-related events to be monitored, correlated, and investigated through centralized security analytics.

---

# 📚 References

- [Microsoft Learn — Active Directory Domain Services Overview](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview)

- [Microsoft Learn — Active Directory PowerShell Module](https://learn.microsoft.com/en-us/powershell/module/activedirectory/)

- [Microsoft Learn — Active Directory Security Groups](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-groups)

- [Microsoft Learn — Fine-Grained Password Policies](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/adac/fine-grained-password-policies)

---

# 🏁 Conclusion

This project demonstrates the implementation of a structured Active Directory administration environment using Windows Server 2022 and PowerShell.

Through OU design, automated account provisioning, security group management, administrative delegation, and Fine-Grained Password Policies, the lab explores several core responsibilities of enterprise IT administration.

The project strengthened my practical understanding of **Active Directory, identity and access management, PowerShell automation, role-based access control, and least-privilege administration**.

It also establishes a foundation for more advanced work involving Group Policy, Windows Server administration, identity security monitoring, and automated user lifecycle management.
