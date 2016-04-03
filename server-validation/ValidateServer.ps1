$inputXML = @"
<Window x:Class="WpfApplication2.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApplication2"
        mc:Ignorable="d"
        Title="Server Validation" Height="250" Width="500" WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
    <Grid>
     <PasswordBox KeyboardNavigation.TabIndex="1" x:Name="tbOrionPass" HorizontalAlignment="Left" Height="25" Margin="228,10,0,0" VerticalAlignment="Top" Width="120"/>
     <TextBox KeyboardNavigation.TabIndex="0" x:Name="tbOrionName" HorizontalAlignment="Left" Height="25" Margin="103,10,0,0" VerticalAlignment="Top" Width="120"/>
     <Button KeyboardNavigation.IsTabStop="False" x:Name="btnOrionTest" Content="Test" HorizontalAlignment="Left" Margin="353,10,0,0" VerticalAlignment="Top" Width="71" Height="25"/>
     <Image x:Name="imgOrionOK" HorizontalAlignment="Left" Height="32" Margin="429,6,0,0" VerticalAlignment="Top" Width="32" Source="grey.png"/>
     <Label Content="Orion Credentials" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="0,9,0,0"/>

     <PasswordBox KeyboardNavigation.TabIndex="3" x:Name="tbAdmPass" HorizontalAlignment="Left" Height="25" Margin="228,50,0,0" VerticalAlignment="Top" Width="120"/>
     <TextBox KeyboardNavigation.TabIndex="2" x:Name="tbAdmName" HorizontalAlignment="Left" Height="25" Margin="103,50,0,0" VerticalAlignment="Top" Width="120"/>
     <Button KeyboardNavigation.IsTabStop="False" x:Name="btnAdmTest" Content="Test" HorizontalAlignment="Left" Margin="353,50,0,0" VerticalAlignment="Top" Width="71" Height="25"/>
     <Image x:Name="imgAdmOK" HorizontalAlignment="Left" Height="32" Margin="429,46,0,0" VerticalAlignment="Top" Width="52" Source="grey.png"/>
     <Label Content="Admin Credentials" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="0,49,0,0"/>
     <CheckBox x:Name="chkLocalAcc" Content="Local account (not domain)" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="5,80,0,0"/>


     <Label Content="Hostname" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="0,120,0,0"/>

     <TextBox KeyboardNavigation.TabIndex="100" x:Name="tbHostname" HorizontalAlignment="Left" Height="25" Margin="103,120,0,0" VerticalAlignment="Top" Width="120"/>

     <Label Content="IP Address" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="0,150,0,0"/>
     <TextBox KeyboardNavigation.TabIndex="101" x:Name="tbIPAddress" HorizontalAlignment="Left" Height="25" Margin="103,150,0,0" VerticalAlignment="Top" Width="120"/>

     <Button KeyboardNavigation.IsTabStop="False" x:Name="btnValidate" Content="Start Validation" HorizontalAlignment="Left" Margin="103,180,0,0" VerticalAlignment="Top" Width="100" Height="25"/>

    </Grid>
</Window>

"@       

. $PSScriptRoot\main\config.ps1
. $PSScriptRoot\main\main.ps1
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window' -replace 'Source="',"Source=`"$PSScriptRoot\main\"
 
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$xaml = $inputXML
$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
try{
    $Form=[Windows.Markup.XamlReader]::Load( $reader )
} catch {
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
}
 
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "DMV$($_.Name)" -Value $Form.FindName($_.Name)}
# start

# $($DMVtbOrionName.Text)

function _checkAdmCredential {
    if($DMVchkLocalAcc.IsChecked){
        $DMVimgAdmOK.Source = "$PSScriptRoot\main\green.png"
        $pa = (ConvertTo-SecureString –String $DMVtbAdmPass.Password –AsPlainText -Force)
        $global:AdmCred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $DMVtbAdmName.Text, $pa
        return $true
    }

    try {
        $pa = (ConvertTo-SecureString –String $DMVtbAdmPass.Password –AsPlainText -Force)
        $global:AdmCred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $DMVtbAdmName.Text, $pa
        $currDomain = "LDAP://" + ([ADSI]"").distinguishedName
        $domain = New-Object System.DirectoryServices.DirectoryEntry($currDomain,$DMVtbAdmName.Text,$AdmCred.GetNetworkCredential().Password)
        if ($domain.name -eq $null){
            $DMVimgAdmOk.Source = "$PSScriptRoot\main\red.png"
            return $false
        }
    } catch {
        $DMVimgAdmOk.Source = "$PSScriptRoot\main\red.png"
        throw [System.Exception] "ADM Credentials error"
        return $false
    } 
    $DMVimgAdmOK.Source = "$PSScriptRoot\main\green.png"
    return $true
}


function _checkOrionCredential {
    try {
        if (!(Get-PSSnapin | where {$_.Name -eq "SwisSnapin"})) { Add-PSSnapin "SwisSnapin" -ErrorAction Stop }
        $po = (ConvertTo-SecureString –String $DMVtbOrionPass.Password –AsPlainText -Force)
        $global:OrionCred = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $DMVtbOrionName.Text, $po

        $Swis = Connect-Swis -Hostname $config.OrionServer -Credential $OrionCred
        $Swis.Open()
    } catch {
      $DMVimgOrionOk.Source = "$PSScriptRoot\main\red.png"
      return $false
    } 
    $DMVimgOrionOK.Source = "$PSScriptRoot\main\green.png"
    $Swis.Close()
    $Swis.Dispose()
    return $true
}

$DMVbtnAdmTest.Add_Click({
    $global:AdmCredsOK = _checkAdmCredential
})

$DMVbtnOrionTest.Add_Click({
    $global:OrionCredsOK = _checkOrionCredential
})

$DMVbtnValidate.Add_Click({
    try {
        #$DMVbtnOrionTest.RaiseEvent((New-Object -TypeName System.Windows.RoutedEventArgs -ErrorAction Stop -ArgumentList $([System.Windows.Controls.Button]::ClickEvent)))        
        #$DMVbtnAdmTest.RaiseEvent((New-Object -TypeName System.Windows.RoutedEventArgs -ErrorAction Stop -ArgumentList $([System.Windows.Controls.Button]::ClickEvent)))        
        $global:OrionCredsOK = _checkOrionCredential
        $global:AdmCredsOK = _checkAdmCredential
    } catch {
        Write-Host "Credential object creation error"
        return 
    }

    if($OrionCredsOK -and $AdmCredsOK){
        try {
            

            if($DMVchkLocalAcc.IsChecked){
                Validate-Server -OrionCredential $OrionCred -AdmCredential $AdmCred -Hostname $($DMVtbHostname.Text) -IP $($DMVtbIPAddress.Text) -Path $PSScriptRoot -SkipAD
            } else {
                Validate-Server -OrionCredential $OrionCred -AdmCredential $AdmCred -Hostname $($DMVtbHostname.Text) -IP $($DMVtbIPAddress.Text) -Path $PSScriptRoot
            }


        } catch {
            Write-Host "Invoke error"
        }

    } else {
        Write-Host "Credentials not valid (Orion or Adm)($OrionCredsOK : $AdmCredsOK)"
        return
    }

})

$DMVtbOrionPass.Add_KeyDown({
    if($args[1].key -eq 'Return'){
        $DMVbtnOrionTest.RaiseEvent((New-Object -TypeName System.Windows.RoutedEventArgs -ArgumentList $([System.Windows.Controls.Button]::ClickEvent)))        
    }
})

$DMVtbAdmPass.Add_KeyDown({
    if($args[1].key -eq 'Return'){
        $DMVbtnAdmTest.RaiseEvent((New-Object -TypeName System.Windows.RoutedEventArgs -ArgumentList $([System.Windows.Controls.Button]::ClickEvent)))        
    }
})


$Form.ShowDialog() | out-null