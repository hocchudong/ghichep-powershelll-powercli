# William Lam
# www.williamlam.com
# Modify: CongTO
$StartTime = Get-Date

$Telegramtoken = "1117214915:AAF4LFh6uChng056_oTyM6cz9TY4dyAn3YU"
$Telegramchatid = "717154123"

Function Send-Telegram {
Param([Parameter(Mandatory=$true)][String]$Message)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($Telegramtoken)/sendMessage?chat_id=$($Telegramchatid)&text=$($Message)"}


$verboseLogFile = "C:\Nested\mylogfile.log"

# Dinh nghia ham co ten la "My-Logger" de hien thi noi dung khi can
Function My-Logger {
    param(
    [Parameter(Mandatory=$true)][String]$message,
    [Parameter(Mandatory=$false)][String]$color="green"
    )

    $timeStamp = Get-Date -Format "MM-dd-yyyy_hh:mm:ss"

    Write-Host -NoNewline -ForegroundColor White "[$timestamp]"
    Write-Host -ForegroundColor $color " $message"
    $logMessage = "[$timeStamp] $message"
    $logMessage | Out-File -Append -LiteralPath $verboseLogFile
}



$vcname = "vc.hcdlab.local"
$vcuser = "administrator@vsphere.local"
$vcpass = "Homelab@2020"

$ovffile = "C:\Nested\Nested_ESXi7.0u2a_Appliance_Template_v1.ovf"

$cluster = "HCD-Cluster02"
$Trunk_Network = "dvpg-nested-trunk"
$datastore = "datastore3-r620"
$iprange = "192.168.20"
$netmask = "255.255.255.0"
$gateway = "192.168.20.1"
$dns = "192.168.20.5"
$dnsdomain = "nsxtlab.local"
$ntp = "192.168.20.212"
$syslog = "192.168.20.212"
$password = "VMware1!"
$ssh = "True"
$network_name = "dvpg-vlan-20"

#### DO NOT EDIT BEYOND HERE ####

$vcenter = Connect-VIServer $vcname -User $vcuser -Password $vcpass -WarningAction SilentlyContinue

$datastore_ref = Get-Datastore -Name $datastore
# $network_ref = Get-VirtualPortGroup -Name $vmnetwork
$cluster_ref = Get-Cluster -Name $cluster
$vmhost_ref = $cluster_ref | Get-VMHost | Select -First 1

$ovfconfig = Get-OvfConfiguration $ovffile


foreach ($i in 81..85){
    $ipaddress = "$iprange.$i"
    # Try to perform DNS lookup
    try {
        $vmname = ([System.Net.Dns]::GetHostEntry($ipaddress).HostName).split(".")[0]
    }
    Catch [system.exception]
    {
        $vmname = "vesxi-$i"
    }
    $ovfconfig.NetworkMapping.VM_Network.value = $network_name
	$ovfconfig.common.guestinfo.hostname.value = $vmname
    $ovfconfig.common.guestinfo.ipaddress.value = $ipaddress
    $ovfconfig.common.guestinfo.netmask.value = $netmask
    $ovfconfig.common.guestinfo.gateway.value = $gateway
    $ovfconfig.common.guestinfo.dns.value = $dns
    $ovfconfig.common.guestinfo.domain.value = $dnsdomain
    $ovfconfig.common.guestinfo.ntp.value = $ntp
    $ovfconfig.common.guestinfo.syslog.value = $syslog
    $ovfconfig.common.guestinfo.password.value = $password
    $ovfconfig.common.guestinfo.ssh.value = $ssh

    # Deploy the OVF/OVA with the config parameters
    My-Logger "Deploying $vmname ..."
	Send-Telegram -Message "Bat dau tao: $vmname"
    
    $vm = Import-VApp -Source $ovffile -OvfConfiguration $ovfconfig -Name $vmname -Location $cluster -VMHost $vmhost_ref -Datastore $datastore -DiskStorageFormat thin
    
	My-Logger "Adding vmnic2/vmnic3 to passthrough to Nested ESXi $vmname"
    New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $Trunk_Network -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
    New-NetworkAdapter -VM $vm -Type Vmxnet3 -NetworkName $Trunk_Network -StartConnected -confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
    
    $vm | New-AdvancedSetting -name "ethernet2.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
    $vm | New-AdvancedSetting -Name "ethernet2.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile

    $vm | New-AdvancedSetting -name "ethernet3.filter4.name" -value "dvfilter-maclearn" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
    $vm | New-AdvancedSetting -Name "ethernet3.filter4.onFailure" -value "failOpen" -confirm:$false -ErrorAction SilentlyContinue | Out-File -Append -LiteralPath $verboseLogFile
    
    My-Logger "Updating vCPU & vMEM $vmname"
    Set-VM -Server $viConnection -VM $vm -NumCpu 4 -MemoryGB 24 -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile

    My-Logger "Updating vSAN Cache & Capacity $vmname"
    Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 2" | Set-HardDisk -CapacityGB 50 -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
    Get-HardDisk -Server $viConnection -VM $vm -Name "Hard disk 3" | Set-HardDisk -CapacityGB 300 -Confirm:$false | Out-File -Append -LiteralPath $verboseLogFile
    
    $NowTime = Get-Date
    Send-Telegram -Message "Da tao xong $vmname vao luc $NowTime"
  
	  # $vm | Start-Vm -RunAsync | Out-Null
	
}


$EndTime = Get-Date
$duration = [math]::Round((New-TimeSpan -Start $StartTime -End $EndTime).TotalMinutes,2)

My-Logger "Da tao xong VM!"
My-Logger "Bat dau vao luc: $StartTime"
My-Logger "Ket thuc vao luc: $EndTime"
My-Logger "Tong thoi gian tao: $duration minutes"

Send-Telegram -Message "Da ket thuc luc $EndTime, Tong thoi gian: $duration minutes" 


Read-Host -Prompt "An ENTER de thoat"