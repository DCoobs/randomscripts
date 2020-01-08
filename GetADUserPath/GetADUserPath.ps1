<#
.SYNOPSIS
Prints the location/path of an AD user object.
.DESCRIPTION
This script can be fed a comma-separated list of AD user identities and it wil Group, compares that to the list of members already in the root of the AD group, and adds/removes users to the base AD group as required.
Written by Drew Coobs - University of Illinois
January 2020
.PARAMETER netids
A comma-separated list of AD user identities that you need the AD paths of.
.EXAMPLE
GetADUserPath.ps1 "coobs1,bernsteg"
#>



[CmdletBinding()]
Param([Parameter(Mandatory=$True,Position=1)] [string[]] $netids)
           
Import-Module ActiveDirectory

foreach ($netid in $netids)
{
    try {
        $netidObject = get-aduser -identity $netid -properties canonicalname
        $netidPath = $netidObject.CanonicalName
        #Write-Output "$netid   $netidPath" 
        Write-Output $netidPath
        }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
        {
        #Write-Output "$netid   Cannot find an object with identity: $netid"
        Write-Output "Cannot find an object with identity: $netid"
        }
}
