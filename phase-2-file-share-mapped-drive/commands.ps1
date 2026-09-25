# Phase 2: Departmental file share and GPO mapped drive
# Home lab: jjadamslab.local | DC01 (Windows Server 2025) | C01 (Windows 11 Enterprise)
# No passwords are stored here. The * after /user: makes net use prompt for one.

# ---------------------------------------------------------------
# On DC01 (elevated PowerShell)
# ---------------------------------------------------------------

# Create the departmental folder
New-Item -Path "C:\CompanyShares\IT" -ItemType Directory

# Publish it as an SMB share
New-SmbShare -Name "IT-Share" -Path "C:\CompanyShares\IT" `
    -FullAccess "JJADAMSLAB\Domain Admins" `
    -ChangeAccess "JJADAMSLAB\GG-IT-Users"

# Verify the share and its share level permissions
Get-SmbShare -Name "IT-Share"
Get-SmbShareAccess -Name "IT-Share"

# Review NTFS permissions, grant Modify to the group, then review again
icacls "C:\CompanyShares\IT"
icacls "C:\CompanyShares\IT" /grant "JJADAMSLAB\GG-IT-Users:(OI)(CI)M"
icacls "C:\CompanyShares\IT"

# Group Policy Preferences drive map (built in Group Policy Management Editor):
#   GPO:    IT Department Mapped Drive, linked to the IT users OU
#   Path:   User Configuration > Preferences > Windows Settings > Drive Maps
#   Action: Update | Location: \\DC01\IT-Share | Label: IT Department | Letter: I:

# ---------------------------------------------------------------
# On C01
# ---------------------------------------------------------------

# Confirm name resolution and that the client can find a domain controller
Resolve-DnsName dc01.jjadamslab.local
nltest /dsgetdc:jjadamslab.local

# Manual access test as the domain user
net use \\DC01\IT-Share /user:JJADAMSLAB\jsmith *
dir \\DC01\IT-Share
echo "Project 2 permission test" > \\DC01\IT-Share\jsmith-test.txt
dir \\DC01\IT-Share

# Apply policy, then sign out and back in as jsmith
gpupdate /force

# Final verification after sign in
whoami
net use
dir I:\
