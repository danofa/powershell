$config = @{
    OrionServer = ""

    snmp = @{
        reg_communities = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities'
        reg_pollers = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers'
        valid_communities = @("")
        valid_pollers = @('')
    }

    wsus = @{
        reg_wsus = 'HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WindowsUpdate'
        valid_servers = @('')
        wsus_ip = ''
    }

    sep = @{
        min_ver = '12.1.6'
        installed_name = 'Symantec Endpoint Protection'
        reg_key = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        svc_name = 'SepMasterService'
        reg_groupkey = 'HKLM:\SOFTWARE\Symantec\Symantec Endpoint Protection\SMC\SYLINK\SyLink'
        reg_groupkey64 = 'HKLM:\SOFTWARE\Wow6432Node\Symantec\Symantec Endpoint Protection\SMC\SYLINK\SyLink'
    }

    local_admin_account = ''
    
    vm = @{
        virtual_machine_string = 'VMware'
        vmtools_minver = '9.0.15'
        vmtools_svc_name = 'VMTools'
        reg_key = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        installed_name = 'VMWare Tools'
    }

    os = @{
        vm = 'Datacenter'
        physical = 'Standard'
    }

    glpi = @{
        service_name = 'FusionInventory-Agent'
        installed_name = 'FusionInventory Agent'
        reg_key = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        min_ver = '2.3.16'
        db_addr = ''
        db_user = ''
        db_db = 'glpi'
        db_key = ''
        db_query = 'SELECT * FROM glpi_computers INNER JOIN glpi_ipaddresses ON glpi_computers.id = glpi_ipaddresses.mainitems_id WHERE glpi_computers.Name = '
    }
}