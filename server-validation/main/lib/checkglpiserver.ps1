<#
 .Synopsis
    server validation library script for glpi server configurations
 .DESCRIPTION
    This script checks if the destination machine has been correctly registered in glpi.
 .EXAMPLE
    this should be called from the main validation script, not for general use.
 #>
 function CheckGlpiServer
 {
     [CmdletBinding()]
     [OutputType([System.Object])]
     Param
     (
         # Hostname
         [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]
         $Hostname
     )
 
        # load general config, exposes $config global variable with all general settings.
        . $PSScriptRoot\..\config.ps1
        $result = {} | Select data,msg,status

        # load mysql assembly
        try {
            [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
        } catch {
            Write-Host "unable to load assembly"
        }

        $connectionString = "server=$($config.glpi.db_addr);port=3306;uid=$($config.glpi.db_user);pwd=$($config.glpi.db_key);database=$($config.glpi.db_db)"
        
        $connection = New-Object MySql.Data.MySqlClient.MySqlConnection
        $connection.ConnectionString = $connectionString
        $connection.Open()

        $command = New-Object MySql.Data.MySqlClient.MySqlCommand("$($config.glpi.db_query)'$Hostname'", $connection)
        $dataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
        $dataSet = New-Object System.Data.DataSet
        $recordCount = $dataAdapter.Fill($dataSet, "data")
        if($dataSet.Tables[0].id -le 0){
            $result.msg = 'Server not registered in GLPI'
            $result.status = 1
           
        } else {
            $res = $dataSet.Tables[0]

            $result.data = "IP $($res.name1), Hostname $($res.name), last modified $($res.date_mod)"
            $result.status = 2

        }

        $connection.Close()
        $connection.Dispose()

        $result
}