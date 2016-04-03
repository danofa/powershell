<#
 .Synopsis
    server validation library script to DNS configurations
 .DESCRIPTION
    This script checks dns entries forward and reverse.
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function CheckDns
 {
     [CmdletBinding()]
     [OutputType([System.Object])]
     Param
     (
         # hostname
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]
         $Hostname,
 
         # ip address
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]
         $IP
     )
 
        # load general config, exposes $config global variable with all general settings.
        . $PSScriptRoot\..\config.ps1
        $result = {} | Select data,msg,status
        $ipFound = $False

        try {
             $dns = [System.Net.Dns]::GetHostByName($Hostname)
             $dns.AddressList | % {
                if($_.IPAddressToString -eq $IP){ $ipFound = $True }
             }
        } catch {
            $result.msg = "Error with hostname, unable to resolve"
            $result.status = 1
            return $result
            
        }
 
        if(!$ipFound){
            $result.msg = "IP does not correspond with hostname"
            $result.status = 1
            return $result

        } else {
            $result.data = "FQDN $($dns.HostName), IP $IP"
        }
        $ping = Test-Connection $IP -Quiet
 
        if($ping -eq $False){
            $result.msg = "Host not responding to ping"
            $result.status = 1
            return $result
            
        } else {
            $result.data += ", ping response $ping"
            $result.status = 0
            return $result
        }

 }