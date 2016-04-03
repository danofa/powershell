<#
 .Synopsis
    server validation library script for Symantec Enterprise protection group
 .DESCRIPTION
    This script checks the installed version of SEP on the client.
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function CheckSepGroup
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

        $result = {} | Select data,msg,status
        # get SEP group
        $sepGroup
        
        try {

            Invoke-Command -cn $Server -Credential $Credential -ScriptBlock {
                Get-ChildItem C:\
            } -ErrorAction Stop | Out-Null

            $sepGroup = Invoke-Command -cn $Server -Credential $Credential -ScriptBlock {
                param($regkey) (Get-ItemProperty  $regkey).CurrentGroup

            } -ArgumentList $config.sep.reg_groupkey -ErrorAction SilentlyContinue

            $sepGroup64 = Invoke-Command -cn $Server -Credential $Credential -ScriptBlock {
                param($regkey) (Get-ItemProperty  $regkey).CurrentGroup

            } -ArgumentList $config.sep.reg_groupkey64 -ErrorAction SilentlyContinue

        } catch {
            $result.msg = "error in connection to host"
            $result.status = 1
            return $result
        }

            if($sepGroup){ 
                $result.data = $sepGroup.Trim()
                $result.status = 2

            } elseif ($sepGroup64){ 
                $result.data = $sepGroup64.Trim()
                $result.status = 2

            } else {
                $result.status = 1
                $result.msg = 'SEP not installed / configured / group not found'
            }
            
            $result
}