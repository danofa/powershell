<#
 .Synopsis
    server validation library script for glpi configurations
 .DESCRIPTION
    This script checks .
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function CheckGlpiAgent
 {
     [CmdletBinding()]
     [OutputType([System.Object])]
     Param
     (
         # credentials
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
         $Credential,

         # Server
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]
         $Server
     )
 
        # load general config, exposes $config global variable with all general settings.
        . $PSScriptRoot\..\config.ps1
        $result = {} | Select data,msg,status

        # check glpi agent installed ( fusion inventory ) and running
    $fusionRunning

        try {

            $fusionRunning = Invoke-Command -cn $Server -Credential $Credential -ScriptBlock {
                param($fisvc) Get-Service  | 
                    Where { $_.ServiceName -eq $fisvc }
            } -ArgumentList $config.glpi.service_name -ErrorAction Stop

            if($fusionRunning.status -ne 'Running'){
                $result.msg = 'Agent service not running or not installed'
                $result.status = 1
                return $result
            }

        } catch {
            $result.msg = "error in connection to host"
            $result.status = 1
            return $result
        }


        $fusionVer = Invoke-Command -cn $Server -Credential $Credential -ScriptBlock {
            param($regkey, $toolsname) Get-ItemProperty  $regkey | 
                    Where { $_.DisplayName -like $toolsname }

        } -ArgumentList $config.glpi.reg_key, "*$($config.glpi.installed_name)*" -ErrorAction Stop

        if([System.Version]$fusionVer.DisplayVersion.substring(0,$config.glpi.min_ver.length) -lt [System.Version]$config.glpi.min_ver){
            $result.msg = "Agent version bad: $($fusionVer.DisplayVersion)"
            $result.status = 1
            return $result
        }

        $result.data = "Version $($fusionVer.DisplayVersion) : Service $($fusionRunning.status)"
        $result.status = 0
        $result
 }