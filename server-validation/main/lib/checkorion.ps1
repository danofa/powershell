<#
 .Synopsis
    server validation library script to check server in AIM
 .DESCRIPTION
    This script connects to AIM and checks to see if the server exists and returns its managed state and information 
    entered.
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function CheckOrion
 {
     [CmdletBinding()]
     [OutputType([System.Object])]
     Param
     (
         # Credentials to use for orion login
         [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
         $Credential,
 
         # Server to check for
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]
         $IP
     )
 
        # load general config, exposes $config global variable with all general settings.
        . $PSScriptRoot\..\config.ps1

        # load SwisSnapin
        try {
            if (!(Get-PSSnapin | where {$_.Name -eq "SwisSnapin"})) {
                Add-PSSnapin "SwisSnapin" -ErrorAction Stop
            }
        } catch {
            Write-Host -ForegroundColor Red -BackgroundColor Yellow "Unable to load SwisSnapin, is the Orion SDK installed?"
            return
        }

        $Swis = Connect-Swis -Host $config.OrionServer -Credential $Credential
        $res = Get-SwisData $Swis -Query "Select Status, StatusDescription, Caption, IP FROM Orion.Nodes WHERE IP = '$IP'"
        
        $result = {} | Select data, status, msg
        if($res){
            $result.data =  "$($res.StatusDescription), $($res.Caption), $($res.IP)"
            $result.status = 0

        } else {
            $result.msg = 'Not found in AIM'
            $result.status = 1
        }

        $result

        $Swis.Close()
        $Swis.Dispose()
 }