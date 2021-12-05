#Import VMware Module
# Import-Module VMware.VimAutomation.Core

$ESX1 = "192.168.20.191"
$User = "root"
$Password = "VMware1!"

Disconnect-VIServer *
Connect-VIServer -Server $ESX1 -User $User -Password $Password -WarningAction SilentlyContinue

#List NIC installed
Get-VMHostNetworkAdapter 

$vSwitch = "vS_UAT"
$PortGroup = "vKernel"

#Create new vSwitch
New-VirtualSwitch -VMHost $ESX1 -Name $vSwitch -nic vmnic2

#Create new Port Group 
Get-VirtualSwitch -name $vSwitch | New-VirtualPortGroup -Name $PortGroup

#New Kernel 
New-VMHostNetworkAdapter -VMhost $ESX1 -PortGroup $PortGroup -VirtualSwitch $vSwitch -IP 192.168.30.191 -SubnetMask 255.255.255.0 -VMotionEnabled $true -VsanTrafficEnabled $true -Mtu 9000 

Read-Host -Prompt "An ENTER de thoat"