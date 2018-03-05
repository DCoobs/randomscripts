<#
.SYNOPSIS

Flattens Active Directory Groups.
.DESCRIPTION

Get all nested members of an Active Directory Group, compares that to the list of members already in the root of the AD group, and adds/removes users to the base AD group as required.

Written by Drew Coobs - University of Illinois
February 2018
.PARAMETER adGroup

The name of the Active Directory group you wish to flatten.

.EXAMPLE
FlattenADGroup "MunkiReport-Managers"
#>

[CmdletBinding()]
Param([Parameter(Mandatory=$True,Position=1)] [string]$adGroup)
           
Import-Module ActiveDirectory

# Output name of specified AD group
"AD Group To Flatten: $adGroup"

# Get array of users that are already in root of base AD group (excludes nested users)
$rootMembers = Get-ADGroupMember -Identity $adGroup | Where-Object {$_.objectClass -eq 'user'}

# Gets all unique, nested users that are indirect members of base AD group
$groupMembers = Get-ADGroupMember -Identity $adGroup | Where-Object {$_.objectClass -eq 'group'} | Get-ADGroupMember -Recursive | Select-Object -Unique

# If both base AD group and nested AD groups are empty
# Exit without making any changes
If (($rootMembers -eq $null) -and ($groupMembers -eq $null))
    {
    "No users with either direct or indirect membership found in $adGroup"
    "Exiting without making changes."
    Exit 0
    }

# Print output if direct members is empty
If ($rootMembers -eq $null)
    {
    "No users with direct membership in $adGroup found."
    }

# Print output if indirect members is empty
If ($groupMembers -eq $null)
    {
    "No users with indirect membership in $adGroup found."
    }

# Returns which users need to be removed from base AD group (no longer member of nested groups)
If (($rootMembers -ne $null) -and ($groupMembers -ne $null))
    {
    $usersToRemove = Compare-Object $rootMembers $groupMembers -PassThru | Where-Object {$_.SideIndicator -eq "<="} | Select SamAccountName
    }

# Returns which users need to be added to base AD group (member of nested groups but not in base AD group)
If (($rootMembers -ne $null) -and ($groupMembers -ne $null))
    {
    $usersToAdd = Compare-Object $rootMembers $groupMembers -PassThru | Where-Object {$_.SideIndicator -eq "=>"} | Select SamAccountName
    }

# If there are members of both nested and base AD groups
# Remove all inactive users from base AD group
If ($usersToRemove -ne $null)
    {
    $usersToRemove | ForEach-Object {
    Remove-ADGroupMember -Identity $adGroup -Members $_ -Confirm:$false
    "Removed $_"}
    }
# Else if there are no nested users but there are users in base AD group
# Remove users in base AD group to match nested groups
ElseIf (($groupMembers -eq $null) -and ($rootMembers -ne $null))
    {
    $rootMembers | ForEach-Object {
    Remove-ADGroupMember -Identity $adGroup -Members $_ -Confirm:$false
    "Removed $_"}
    }

# If there are members of both nested and base AD groups
# Add all newly active users to base AD group
If ($usersToAdd -ne $null)
    {
    $usersToAdd | ForEach-Object {
    Add-ADGroupMember -Identity $adGroup -Members $_ -Confirm:$false
    "Added $_"}
    }
# Else if there are no users in base AD group but there are nested users
# Add the nested users to base AD group
ElseIf (($rootMembers -eq $null) -and ($groupMembers -ne $null))
    {
    $groupMembers | ForEach-Object {
    Add-ADGroupMember -Identity $adGroup -Members $_ -Confirm:$false
    "Added $_"}
    }

# If there is no net change to group membership, print output
If (($usersToAdd -eq $null) -and ($usersToRemove -eq $null))
    {
    "No net change for user membership of $adGroup"
    }
