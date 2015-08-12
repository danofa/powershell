# Apply network drive mappings based on Group
# Copyright (c) 2015 Dion Mitchell
# License Apache 2.0

# information for users, drives to map and network share path are stored here
$driveMappings = @{
        'Technicians' = @{'path' = '\\svr.home.lan\techs'; 'letter' = 'T:' };
        'Directors' = @{'path' = '\\svr.home.lan\dirs'; 'letter' = 'B:' }
        }

$netObj = New-Object -ComObject "Wscript.Network"
$dsSearch = (New-Object System.DirectoryServices.DirectorySearcher("(&(objectCategory=User)(samAccountName=$($env:username)))")).FindOne().GetDirectoryEntry().memberOf

$driveMappings.GetEnumerator() | % {
    if($dsSearch -like "*CN="+ $_.key +",*"){ $netObj.MapNetworkDrive($_.value.letter, $_.value.path) } 
}