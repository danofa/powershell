# main validation script

function Validate-Server {

Param(
        [Parameter(Mandatory=$true)]
        $OrionCredential = (Get-Credential -message "Enter AIM Credentials"),
        [Parameter(Mandatory=$true)]
        $AdmCredential = (Get-Credential -message "Enter your ADM Account Credentials") ,
        [Parameter(Mandatory=$true)][string]
        $Hostname,
        [Parameter(Mandatory=$true)][string]
        $IP,
        [Parameter(Mandatory=$true)][string]
        $Path, 
        [switch]
        $SkipAD

)

# lib scripts
. $Path\main\lib\checkosversion.ps1
. $Path\main\lib\checksnmp.ps1
. $Path\main\lib\checksep.ps1
. $Path\main\lib\checksepgroup.ps1
. $Path\main\lib\checkwsus.ps1
. $Path\main\lib\checkglpiagent.ps1
. $Path\main\lib\checkglpiserver.ps1
. $Path\main\lib\checkorion.ps1
. $Path\main\lib\checkadminaccount.ps1
. $Path\main\lib\checkvm.ps1
. $Path\main\lib\checkdns.ps1
. $Path\main\lib\checkvmtools.ps1
. $Path\main\lib\utils.ps1
. $Path\main\lib\checkactivedirectory.ps1
. $Path\main\lib\checkpagefile.ps1

$commands = @{
    '2.1  - Hostname resolves and pings' = 'CheckDns -Hostname $Hostname -IP $IP'
    '2.2  - SNMP Installed and configured' = 'CheckSnmp -Credential $AdmCredential -Server $IP'
    '2.3  - Admin account' = 'CheckAdminAccount -Server $IP -Credential $AdmCredential'
    '2.4  - Check GLPI Agent' = 'CheckGlpiAgent -Server $IP -Credential $AdmCredential'
    '2.5  - Check GLPI Server' = 'CheckGlpiServer -Hostname $Hostname'
    '2.6  - SEP Version and configured' = 'CheckSep -Credential $AdmCredential -Server $IP'
    '2.7  - SEP Policy ( Group )' = 'CheckSepGroup -Credential $AdmCredential -Server $IP'
    '2.11 - WSUS Configuration' = 'CheckWsus -Credential $AdmCredential -Hostname $Hostname -IP $IP'
    '3.8  - AIM Discovered' = 'CheckOrion -IP $IP -Credential $OrionCredential'
    'XTR  - Page file configuration' = 'CheckPageFile -Credential $AdmCredential -Server $IP'
    }
    
    if(!$SkipAD){
        $commands.Add('2.8  - Active Directory', 'CheckActiveDirectory -Credential $AdmCredential -IP $IP -Hostname $Hostname')
    }

    # easy fire checks 
    $timestamp = Get-Date -UFormat "%Y%m%d-%H%M" | foreach {$_ -replace ":", ""}
    $logFile = "$Path\temp_$(Get-Random)"

    Log " - Begin server validation: $Hostname / $IP" -Out $logFile

    $warns, $oks, $errs = 0
    $commands.GetEnumerator() | % {
        
        $result = Invoke-Expression $_.Value

        if($result.status -eq 0){
            Log -Type 0 "$($_.Key) : $($result.data)" -Out $logFile
            $oks++
        
        } elseif($result.status -eq 1){ 
           Log -Type 1 "$($_.Key) : $($result.msg)" -Out $logFile
           $errs++
        
        } elseif($result.status -eq 2){ 
           Log -Type 2 "$($_.Key) : $($result.data)" -Out $logFile
           $warns++
        }
    }

    # specific run of commands to chain together validation ( os version and vm tools for example )
    
    # vm/physical checking
    $checkVM = CheckVM -Credential $AdmCredential -IP $IP
    if($checkVM.status -eq 0){
        Log -Type 0 -Message "2.9  - Virtual or Physical Machine : $($checkVM.data)" -Out $logFile
        $osVersion = CheckOsVersion -Server $IP -Credential $AdmCredential -Phys
        $oks++

        if($osVersion.status -eq 0){
            Log -Type 0 -Message "2.12 - OS Version : $($osVersion.data)" -Out $logFile
            $oks++
        } else {
            $errs++
            Log -Type 1 -Message "2.12 - OS Version : $($osVersion.msg)" -Out $logFile
        }

    } elseif($checkVM.status -eq 3){ # status 3 = VM

        $osVersion = CheckOsVersion -Server $IP -Credential $AdmCredential -VM
        if($osVersion.status -eq 0){
            $oks++
            Log -Type 0 -Message "2.12 - OS Version : $($osVersion.data)" -Out $logFile
        } else {
            $errs++
            Log -Type 1 -Message "2.12 - OS Version : $($osVersion.msg)" -Out $logFile
        }
    
        $checkVMTools = CheckVMTools -Server $IP -Credential $AdmCredential
        if($checkVMTools.status -eq 0){
            $oks++
            Log -Type 0 -Message "2.9  - Virtual machine VM tools : $($checkVMTools.data)" -Out $logFile
        } else {
            $errs++
            Log -Type 1 -Message "2.9  - Virtual machine VM tools : $($checkVMTools.msg)" -Out $logFile
        }

    } elseif($checkVM.status -eq 1){
        $errs++
        Log -Type 1 -Message "2.9  - Virtual or Physical Machine : $($checkVM.msg)" -Out $logFile
    }
    

    Log " - Server validation finished, $($oks+$errs+$warns) items checked:" -Out $logFile
    Log -Type 0 " - Passed: $oks" -Out $logFile
    Log -Type 2 " - Warnings: $warns" -Out $logFile
    Log -Type 1 " - Errors: $errs" -Out $logFile

    Get-Content $logFile | Sort | Out-File -FilePath "$Path\$timestamp-$Hostname-$IP.txt"
    Remove-Item $logFile -Force

    Write-Host "Output file saved to: $Path\$timestamp-$Hostname-$IP.txt"
## end script data treatment

}