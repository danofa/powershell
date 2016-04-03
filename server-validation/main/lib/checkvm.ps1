<#
 .Synopsis
    server validation library script for virtualmachine configurations
 .DESCRIPTION
    This script checks .
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function CheckVM
 {
     [CmdletBinding()]
     [OutputType([System.Object])]
     Param
     (
         # credentials
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
         $Credential,
 
         # ip address
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]
         $IP
     )
 
        # load general config, exposes $config global variable with all general settings.
        . $PSScriptRoot\..\config.ps1
        $result = {} | Select data,msg,status
        $manufacturer

        try {
            $manufacturer = Invoke-Command -Credential $Credential -ComputerName $IP -script {
                    (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer
            } -ErrorAction Stop

        } catch {
            $result.msg = 'unable to connect to host or error'
            $result.status = 1
            return $result
        }

        if($manufacturer -notlike "*$($config.vm.virtual_machine_string)*"){
            $result.data = "Physical machine: $manufacturer"
            $result.status = 0
           
            
        } else {

            $result.data = "Virtual Machine: $manufacturer"
            $result.status = 3
        }
        
        $result
 }