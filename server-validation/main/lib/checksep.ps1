<#
 .Synopsis
    server validation library script for Symantec Enterprise protection configurations
 .DESCRIPTION
    This script checks the installed version of SEP on the client.
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function CheckSep
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
         $Server
 
     )
 
        # load general config, exposes $config global variable with all general settings.
        . $PSScriptRoot\..\config.ps1

        $result = {} | Select data,msg,status

        try {
            # get sep version

            $sepVer = Invoke-Command -cn $Server -Credential $Credential -ScriptBlock {
                param($regkey, $sepname) Get-ItemProperty  $regkey | 
                    Where { $_.DisplayName -like $sepname }

            } -ArgumentList $config.sep.reg_key, $config.sep.installed_name -ErrorAction Stop

            # check service is running
            $sepRunning = Invoke-Command -cn $Server -Credential $Credential -ScriptBlock {
                param($sepsvc) Get-Service  | 
                    Where { $_.Name -eq $sepsvc }

            } -ArgumentList $config.sep.svc_name

        } catch {
            $result.msg = 'unable to connect to host or error'
            $result.status = 1
            return $result
        }

        if(!$sepVer){
            $result.msg = 'SEP installation not found on destination.'
            $result.status = 1
            return $result

        } elseif($sepRunning.status -ne 'Running'){
            $result.msg = 'SEP service not running on destination.'
            $result.status = 1
            return $result
        }

        $sepVerOrig = $sepVer.DisplayVersion
        $sepVer = $sepVer.DisplayVersion.subString(0,$config.sep.min_ver.length)

        if ([System.Version]$sepVer -ge [System.Version]$config.sep.min_ver){
            $result.data = "Version $sepVerOrig : Service $($sepRunning.status)"
            $result.status = 0 

        } else {
            $result.msg = "Bad version $sepVerOrig : Service $($sepRunning.status)"
            $result.status = 1 
        }

        $result

 }