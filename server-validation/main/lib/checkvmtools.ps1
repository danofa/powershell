<#
 .Synopsis
    server validation library script for virtualmachine tools version and service status
 .DESCRIPTION
    This script checks .
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function CheckVMTools
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
         $Server
     )
 
        # load general config, exposes $config global variable with all general settings.
        . $PSScriptRoot\..\config.ps1
        . $PSScriptRoot\utils.ps1
        $result = {} | Select data,msg,status

        # check service is running
        $vmtoolsRunning = Invoke-Command -cn $Server -Credential $Credential -ScriptBlock {
            param($vmtoolsvc) Get-Service  | 
                Where { $_.Name -eq $vmtoolsvc }

            } -ArgumentList $config.vm.vmtools_svc_name

        if($vmtoolsRunning.status -ne 'Running'){
            $result.msg = "VM Tools not running: $($vmtoolsRunning.status)"
            $result.status = 1
            return $result

        } else {
            # do version check
            $toolsVer = Invoke-Command -cn $Server -Credential $Credential -ScriptBlock {
                param($regkey, $toolsname) Get-ItemProperty  $regkey | 
                    Where { $_.DisplayName -like $toolsname }

            } -ArgumentList $config.vm.reg_key, $config.vm.installed_name -ErrorAction Stop
            
           if([System.Version]$toolsVer.DisplayVersion.substring(0,$config.vm.vmtools_minver.length) -ge 
                    [System.Version]$config.vm.vmtools_minver){
                $result.data = "Tools Version: $($toolsVer.DisplayVersion) : Service $($vmtoolsRunning.status)"
                $result.status = 0

           } else {
                $result.msg = "Tools Version $($toolsVer.DisplayVersion) : Service $($vmtoolsRunning.status)"
                $result.status = 1
           }
        }
        
        $result
 }