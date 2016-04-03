<#
 .Synopsis
    server validation library script for WSUS configurations
 .DESCRIPTION
    This script checks WSUS server is configured on the client, and that is it correctly registered on the server.
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function CheckWsus
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
         $Hostname,

         # ipaddress
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]
         $IP
 
     )
 
        # load general config, exposes $config global variable with all general settings.
        . $PSScriptRoot\..\config.ps1

        # setup result hash.
        $result = {} | Select msg,data,status
        $wsusSettings

        try {
            $wsusSettings = Invoke-Command -Credential $Credential -ComputerName $IP -Script { 
               Param($path) get-itemproperty -path $path -ErrorAction SilentlyContinue
            } -ArgumentList "Registry::$($config.wsus.reg_wsus)" -ErrorAction Stop | Select WUServer, WUStatusServer

        } catch {
            $result.msg = 'Cannot connect or not configured'
            $result.status = 1
            return $result
        }

        # check server registry settings
        if(!$config.wsus.valid_servers.Contains($wsusSettings.WUServer) -or 
                !$config.wsus.valid_servers.Contains($wsusSettings.WUStatusServer)){
            $result.msg = "WUServer not configured. $($wsusSettings.WUStatusServer + ':'+ $wsusSettings.WUServer)"
            $result.status = 1
            return $result
        } else {
            $foundWsus = ([System.Uri]$wsusSettings.WUStatusServer).DnsSafeHost
        }

        # get wsus server group of this machine.
        try {
            [void][reflection.assembly]::LoadWithPartialName(“Microsoft.UpdateServices.Administration”)
        } catch {
            Write-Host -ForegroundColor Red -BackgroundColor Yellow "Unable to load Administration assembly, did you install the WSUS Admin console?"
            return
        }
        
        # get wsus object 
        try {
                $wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($foundWsus,$False) #$config.wsus.wsus_ip
        } catch {
            if($Error[0] -like "*Request for principal permission failed*"){
                $result.msg = "Credentials error, did you run this console as your adm account?"
                $result.status = 1
			}
			return $result
		}

        	    
        $targetGroup = [void]
        $searchResults = $wsus.SearchComputerTargets($Hostname) 
        $searchResults | % {

            if(($_.FullDomainName.Split('.'))[0] -eq $Hostname){
                $targetGroup = $_.GetComputerTargetGroups() | Select Name
                $result.data =  "Groups = $($targetGroup | % { $_.Name + ', '})"
                $result.status = 2
                return $result
            }

        }
        

        if($targetGroup -eq [void]){
            $result.msg = "Target group not found for host (Not in WSUS grouping)."
            $result.status = 1
            return $result
        }
 }
