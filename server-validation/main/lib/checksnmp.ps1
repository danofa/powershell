<#
 .Synopsis
    server validation library script for SNMP configuration
 .DESCRIPTION
    This script checks snmp service installed, running, community sgipnet and 3 aim pollers and dev poller.
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function CheckSnmp
 {
     [CmdletBinding()]
     [OutputType([System.Object])]
     Param
     (
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
         $Credential,

         # machine to check
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]
         $Server
     )
 
   
        # load general config, exposes $config global variable with all general settings.
        . $PSScriptRoot\..\config.ps1
        $result = {} | Select msg,data,status
    
        
        try {
            $snmpsvc = Invoke-Command -Credential $Credential -ComputerName $Server -script {
                Get-Service -Name SNMP -ErrorAction stop 
            } -ErrorAction Stop

        } catch {
            $result.msg = 'SNMP service not installed or cannot connect'
            $result.status = 1
            return $result
        }

        if($snmpsvc.Status -ne 'Running'){
            $result.msg = 'SNMP service not running'
            $result.status = 1
            return $result
        }
        
        $communitiesfound = $false
        $pollersfound = $false

        $communities = Invoke-Command -Credential $Credential -ComputerName $Server -Script { 
           Param($path) Get-ItemProperty -path $path
        } -ArgumentList "Registry::$($config.snmp.reg_communities)"
        
        $pollers = Invoke-Command -Credential $Credential -ComputerName $Server -Script { 
           Param($path) Get-ItemProperty -path $path
        } -ArgumentList "Registry::$($config.snmp.reg_pollers)"

        if(!$communities -or !$pollers){
            $result.msg = 'SNMP Community or pollers not configured'
            $result.status = 1
            return $result
        }

        [System.Collections.ArrayList]$collectedPollers = @()
        $pollers.psobject.properties | % { [void]$collectedPollers.Add($_.Value) }

        [System.Collections.ArrayList]$collectedCommunities = @()
        $communities.psobject.properties | % { [void]$collectedCommunities.Add($_.Name) }

        $config.snmp.valid_communities | % {
            if($collectedCommunities.Contains($_)){
                $communitiesfound = $true
            } else {
                $communitiesfound = $false
            }
        }

        $config.snmp.valid_pollers | % {
            if($collectedPollers.Contains($_)){
                $pollersfound = $true
            } else {
                $pollersfound = $false
            }
        }


        if(!$pollersfound){
            $result.msg = 'Poller settings not valid (missing pollers)'
            $result.status = 1

        } elseif(!$communitiesfound){
            $result.msg = 'Community settings not valid (missing communities)'
            $result.status = 1

        } else {
            $result.data = "communities: $($config.snmp.valid_communities)"
            $result.data += ", pollers: $($config.snmp.valid_pollers)"
            $result.status = 0

        }

        $result
 }