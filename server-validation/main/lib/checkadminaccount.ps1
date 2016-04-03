<#
 .Synopsis
    server validation library script for local admin user configuration
 .DESCRIPTION
    This script checks to see if windows local admin account installed (edcadm).
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function CheckAdminAccount
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

        $result = {} | Select msg, data, status
        try {
        $user = Invoke-Command -cn $Server -Credential $Credential -ScriptBlock {
                param($user) Get-WmiObject -Class Win32_UserAccount -filter "LocalAccount = 'True'"  | Where {$_.Name -eq $user}

            } -ArgumentList $config.local_admin_account -ErrorAction Stop
        } catch {
            $result.msg = "error in connection to host"
            $result.status = 1
            return $result
        }

        if(!$user){
            $result.msg = "Account '$($config.local_admin_account)' not found on destination machine."
            $result.status = 1

        } else {
            $result.data = $user
            $result.status = 0
        }

        $result
}


