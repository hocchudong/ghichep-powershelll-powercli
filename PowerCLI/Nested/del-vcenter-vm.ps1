$iprange = "192.168.20"

# 190..192 | Foreach {
    # $ipaddress = "$iprange.$_"
    # # Try to perform DNS lookup
    # try {
        # $vmname = ([System.Net.Dns]::GetHostEntry($ipaddress).HostName).split(".")[0]
    # }
    # Catch [system.exception]
    # {
        # $vmname = "vesxi-vsan-$ipaddress"
    # }
    
    # Get-VM -Name $vmname | Start-Vm -RunAsync | Out-Null
# }


foreach ($i in 191..193) {
    $ipaddress = "$iprange.$_"
    # Try to perform DNS lookup
    try {
        $vmname = ([System.Net.Dns]::GetHostEntry($ipaddress).HostName).split(".")[0]
    }
    Catch [system.exception]
    {
        $vmname = "vesxi-$i"
    }
    
    ##Get-VM -Name $vmname | Stop-Vm -RunAsync | Out-Null
    Get-VM -Name $vmname | Stop-VM -Confirm:$false -RunAsync
}

foreach ($i in 191..193){
    $ipaddress = "$iprange.$_"
    # Try to perform DNS lookup
    try {
        $vmname = ([System.Net.Dns]::GetHostEntry($ipaddress).HostName).split(".")[0]
    }
    Catch [system.exception]
    {
        $vmname = "vesxi-$i"
    }
    
    ##Get-VM -Name $vmname | Stop-Vm -RunAsync | Out-Null
    Remove-VM -VM $vmname -DeletePermanently -Confirm:$false
}