<#
 .Synopsis
    server validation library script for <template> configurations
 .DESCRIPTION
    This script checks .
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function Check<something>
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


 }