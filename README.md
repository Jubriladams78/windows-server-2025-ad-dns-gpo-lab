# Windows Server 2025 Active Directory, DNS & Group Policy Home Lab

I built this lab on my own machine to get real practice running a small Windows domain from scratch. It uses two Hyper-V virtual machines: a Windows Server 2025 domain controller and a Windows 11 Enterprise workstation. On that setup I stood up Active Directory, DNS, a clean OU layout, a test user and security group, and a Group Policy Object, and then I proved each piece worked with PowerShell.

This is a home lab, not a production environment. I did it to build the hands on skills that IT Support, Desktop Support, Microsoft 365 Support, and Junior Systems Administrator roles call for every day.

## The Environment

| System | Role | IPv4 | DNS Server | Domain |
|---|---|---|---|---|
| DC01 | Windows Server 2025 domain controller and DNS | 10.20.30.10/24 | Itself | jjadamslab.local |
| C01 | Windows 11 Enterprise domain workstation | 10.20.30.20/24 | 10.20.30.10 | jjadamslab.local |

Both machines sit on a Hyper-V internal switch called `Lab01-Internal` on the `10.20.30.0/24` subnet.

**Tools and technologies:** Hyper-V, Windows Server 2025, Windows 11 Enterprise, Active Directory Domain Services, DNS, Group Policy, PowerShell, Windows Firewall, and TCP/IP networking.

## How I Built It

1. Connected DC01 and C01 to the same Hyper-V internal switch.
2. Gave both machines static IPv4 addresses and pointed C01 at DC01 for DNS.
3. Confirmed the two machines could reach each other.
4. Installed Active Directory Domain Services on DC01 and promoted it as the first domain controller in a new `jjadamslab.local` forest.
5. Checked that AD DS, DNS, and Netlogon were running and that the domain and forest looked healthy.
6. Joined C01 to the domain.
7. Created an OU layout with top level OUs for users, computers, and groups, plus IT, Sales, and HR under the users OU.
8. Moved C01 out of the default Computers container and into the managed computers OU.
9. Created a test IT user, James Smith (`jsmith`), and added him to a new `GG-IT-Users` global security group.
10. Signed in to C01 as jsmith to confirm domain authentication and group membership.
11. Created and linked an `IT Department User Policy` GPO, then confirmed it applied with `gpupdate` and `gpresult`.

## Commands I Used to Verify Each Step

```powershell
Get-NetIPConfiguration -InterfaceAlias "Ethernet"
Resolve-DnsName dc01.jjadamslab.local
Test-Connection dc01.jjadamslab.local -Count 2
Get-ADDomain
Get-ADForest
Get-Service ADWS,DNS,Netlogon
Get-ADComputer C01 -Properties *
Get-ADOrganizationalUnit -Filter *
Get-ADUser "jsmith" -Properties Enabled,UserPrincipalName
Get-ADGroupMember "GG-IT-Users"
gpupdate /force
gpresult /r
```

## What Went Wrong and What I Learned

Not everything worked on the first try, and I learned the most from the parts that broke. I ran into problems with network connectivity, firewall rules, DNS settings, PowerShell syntax, joining the domain, where AD objects landed, and Group Policy processing. Here are the lessons that stuck with me:

* A domain client has to use the domain's DNS server. If it doesn't, it can't find the domain controller, and the domain join fails.
* `Test-Connection` only sends pings. To test whether a specific TCP port is open, you need `Test-NetConnection -Port`.
* PowerShell switch parameters need their leading hyphen. `Restart` does nothing, but `-Restart` works.
* A Distinguished Name like `OU=IT,OU=JJADAMS-Users,DC=jjadamslab,DC=local` is a path to an object. It is not something you can run as a command.
* When you add a user to a new security group, they usually need to sign out and back in before the new membership shows up in their access token.
* I kept Windows Firewall turned on in the final build and only allowed the rules the lab needs, instead of switching it off to make problems go away.

## Screenshots

### 1. Hyper-V internal switch
Both VMs connect to `Lab01-Internal`, an internal only switch I created in Hyper-V Virtual Switch Manager. It keeps lab traffic off my home network.

![Hyper-V Virtual Switch Manager showing Lab01-Internal set to Internal network, with DC01 and C01 listed](screenshots/00_HyperV_Lab01_Internal_Switch.png)

### 2. DC01 static IP and DNS
DC01 has its static address, 10.20.30.10, and I pointed its DNS setting at itself.

![DC01 network configuration showing static IP 10.20.30.10 and its DNS server setting](screenshots/01_DC01_Static_IP_and_DNS.png)

### 3. C01 static IP and DNS
C01 has 10.20.30.20 and uses DC01 as its DNS server.

![C01 showing IP address 10.20.30.20 and DNS server set to 10.20.30.10](screenshots/02_C01_Static_IP_and_DNS.png)

### 4. Connectivity from C01 to DC01
C01 successfully pings the domain controller.

![Test-Connection from C01 to 10.20.30.10 with successful replies](screenshots/03_C01_to_DC01_Connectivity_Test.png)

### 5. Forest and service health
`Get-ADForest` shows the new jjadamslab.local forest, and ADWS, DNS, and Netlogon are all running.

![Get-ADForest output and Get-Service showing ADWS, DNS and Netlogon running](screenshots/04_AD_Forest_and_Service_Health.png)

### 6. DNS resolution and the C01 computer object
DC01 resolves its own name through DNS, and C01 now shows up in Active Directory as a domain computer.

![Resolve-DnsName for dc01.jjadamslab.local and Get-ADComputer showing C01](screenshots/05_DNS_Resolution_and_C01_Computer_Object.png)

### 7. Top level OU structure
I created the JJADAMS-Users, JJADAMS-Computers, and JJADAMS-Groups OUs.

![New-ADOrganizationalUnit commands and the resulting OU list](screenshots/06_Top_Level_OU_Structure.png)

### 8. C01 moved into the managed OU
C01 now sits in the JJADAMS-Computers OU instead of the default Computers container.

![Move-ADObject placing C01 in OU=JJADAMS-Computers](screenshots/07_C01_Moved_to_Computers_OU.png)

### 9. Department OUs
I created IT, Sales, and HR OUs under JJADAMS-Users.

![IT, Sales and HR OUs created under JJADAMS-Users](screenshots/08_Department_OUs.png)

### 10. James Smith user account
I created the test user James Smith in the IT OU under JJADAMS-Users.

![James Smith Properties in Active Directory Users and Computers, with the account in the IT OU](screenshots/08_James_Smith_User_Account.png)

### 11. GG-IT-Users security group
I created `GG-IT-Users` in the JJADAMS-Groups OU as a Global Security group.

![GG-IT-Users properties in Active Directory Users and Computers showing Global scope and Security type](screenshots/08a_GG_IT_Users_Security_Group.png)

### 12. James Smith added to GG-IT-Users
The Members tab shows James Smith, whose account lives in the IT OU under JJADAMS-Users.

![GG-IT-Users Members tab listing James Smith from jjadamslab.local/JJADAMS-Users/IT](screenshots/08b_GG_IT_Users_Members.png)

### 13. Domain sign in and group membership
Signed in to C01 as `jjadamslab\jsmith`, `whoami /groups` lists JJADAMSLAB\GG-IT-Users.

![whoami /groups on C01 as jsmith showing membership in GG-IT-Users](screenshots/09_Domain_Sign_In_and_Group_Membership.png)

### 14. Group Policy Management
This is the jjadamslab.local domain in the Group Policy Management console.

![Group Policy Management console open to the jjadamslab.local domain](screenshots/10_Group_Policy_Management_Console.png)

### 15. Group Policy result
`gpresult /r` on C01 shows that the IT Department User Policy applied to James Smith.

![gpresult output showing IT Department User Policy applied to jsmith](screenshots/11_Group_Policy_Result.png)

## Documentation

I wrote up the full build as a step by step Standard Operating Procedure, so someone else can repeat it from scratch:

* [Lab SOP (Word)](docs/JJADAMS_Windows_Server_AD_DNS_GPO_Lab_SOP.docx)
* [One page project summary (Word)](docs/JJADAMS_GitHub_Portfolio_Project_Document.docx)

## Skills This Lab Shows

Windows Server administration, Active Directory, DNS configuration and troubleshooting, static IPv4 addressing, Hyper-V virtual networking, joining workstations to a domain, user and computer account management, OU design, security groups, Group Policy, PowerShell, troubleshooting, and technical documentation.

## What's Next

For the next phase I plan to add DHCP, SMB file shares with NTFS permissions, more departmental security groups, mapped drives through Group Policy Preferences, printer deployment, password and account lockout policies, and a few more troubleshooting scenarios.

## A Note on Security

Everything here lives in an isolated lab with made up users. I left all passwords and credentials out of this repository on purpose.
