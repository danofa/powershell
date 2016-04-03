<#
 .Synopsis
    server validation library script for <template> configurations
 .DESCRIPTION
    This script checks .
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function CheckOSVersion
 {
     [CmdletBinding()]
     [OutputType([System.Object])]
     Param
     (
         # credentials
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
         $Credential,

         # server
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]
         $Server,

         [Switch]
         $VM,

         [Switch]
         $Phys

     )
 
        # load general config, exposes $config global variable with all general settings.
        . $PSScriptRoot\..\config.ps1
        $result = {} | Select msg, data, status
        $osVersion

        try {
            $osVersion = Invoke-Command -Credential $Credential -ComputerName $Server -Script { 
                return (Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop).Caption 
            } -ErrorAction Stop

        } catch {
            $result.msg = $Error[0]
            $result.status = 1
            return $result
        }

        if($VM) { 
            if(!$osVersion.contains($config.os.vm)){
                $result.status = 1
                $result.msg = "Wrong Operating system for VM: $($osVersion)"
            } else {
                $result.status = 0
            }

        } elseif ($Phys){
            if(!$osVersion.contains($config.os.physical)){
                $result.status = 1
                $result.msg = "Wrong operating system for Physical: $($osVersion)"
            } else {
                $result.status = 0
            }

        } 

        $result.data = $osVersion
        $result
 }