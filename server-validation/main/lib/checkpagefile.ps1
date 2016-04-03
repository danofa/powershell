<#
 .Synopsis
    server validation library script for pagefile configuration
 .DESCRIPTION
    This script checks pagefile configuration.
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function CheckPageFile
 {
     [CmdletBinding()]
     [OutputType([System.Object])]
     Param
     (
         # ADM Credential
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
         $Credential,
 
         # Server
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]
         $Server
     )
 
        # load general config, exposes $config global variable with all general settings.
        . $PSScriptRoot\..\config.ps1
        $result = {} | Select msg,data,status

        $pfManaged = Invoke-Command -cn $Server -Credential $Credential -ScriptBlock {
                        Get-WmiObject Win32_PageFileSetting
                    }

        if($pfManaged){
            $result.data = "Pagefile configured: $($pfManaged | % { $_.Name + ' - '+ $_.MaximumSize + 'mb, ' })"
            $result.status = 2

        } else {

            $pfAuto = Invoke-Command -cn $Server -Credential $Credential -ScriptBlock {
                        Get-WmiObject Win32_PageFileUsage
                    }

            $result.msg = "Pagefile managed by system: $($pfAuto | % { $_.Name + ' - '+ $_.AllocatedBaseSize + 'mb, ' })"
            $result.status = 1
        }

        $result
 }