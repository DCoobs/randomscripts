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

# Set base AD group to use
#$adGroup = "munkireport-test"

"AD Group To Flatten: $adGroup"

# Get array of users that are already in root of base AD group (excludes nested users)
$rootMembers = Get-ADGroupMember -Identity $adGroup | Where-Object {$_.objectClass -eq 'user'}

# Gets all unique users (both nested & non-nested) that are either a member of the base AD group or a member of a nested group(s) contained within the base AD group
$groupMembers = Get-ADGroupMember -Identity $adGroup | Where-Object {$_.objectClass -eq 'group'} | Get-ADGroupMember -Recursive | Select-Object -Unique

# Returns which users need to be removed from base AD group (no longer member of nested groups)
$usersToRemove = $rootMembers | Where {$groupMembers -NotContains $_}

# Returns which users need to be added to base AD group (member of nested groups but not in base AD group)
$usersToAdd = $groupMembers | Where {$rootMembers -NotContains $_}

# Remove all inactive users from base AD group
$usersToRemove | ForEach-Object {
  Remove-ADGroupMember -Identity $adGroup -Members $_.SamAccountName -Confirm:$false
  "Removed $_.SamAccountName"
}

# Add all newly active users to base AD group
$usersToAdd | ForEach-Object {
  Add-ADGroupMember -Identity $adGroup -Members $_.SamAccountName -Confirm:$false
  "Added $_.SamAccountName"
}