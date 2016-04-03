<#
 .Synopsis
    server validation library script for <template> configurations
 .DESCRIPTION
    This script checks .
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function CheckActiveDirectory
 {
     [CmdletBinding()]
     [OutputType([System.Object])]
     Param
     (
         # credentials
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
         $Credential,

         # hostname
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]
         $Hostname,
 
         # ip address
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]
         $IP
     )
 
        # load general config, exposes $config global variable with all general settings.
        . $PSScriptRoot\..\config.ps1
        . $PSScriptRoot\utils.ps1

        $result = {} | Select msg,data,status
        $adinfo = ([adsisearcher]"(&(objectCategory=computer)(objectClass=computer)(cn=$Hostname))").FindOne().Properties.distinguishedname
        $ParsedDN = ParseDN -DN $adinfo

        if($adinfo.distinguishedname -contains 'CN=Computers'){
            $result.msg = "ActiveDirectory OU invalid (CN=Computers) $($ParsedDN.ou)"
            $result.status = 1
        } else {
            $result.data = "$($ParsedDN.cn).$($ParsedDN.domain) in $($ParsedDN.ou)"
            $result.status = 2
        }

        $result
 }