# Cong TO
# Script add tao VSAN Cluser
$VIServer = "vcsa.vsanlab.local"
$VIUsername = "administrator@vsphere.local"
$VIPassword = "VMware1!"

$DataCenter = "MYLAB"
$Cluster = "MYLAB-CLUSTER"

#Distribution Switch
$ESX1 = "vesxi-191.vsanlab.local"
$ESX2 = "vesxi-192.vsanlab.local"
$ESX3 = "vesxi-193.vsanlab.local"

$DS_VSAN = "DS-VSAN"
$DP_VSAN = "DP-VSAN"
$DS_PROD = "DS-PROD"
$DP_PROD = "DP-PROD"

Disconnect-VIServer *
$VCSA = Connect-VIServer -Server $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue

#New Distribution Switch (DS)
New-VDSwitch -NumUplinkPorts 1 -Name $DS_VSAN -mtu 9000 -Location $DataCenter
New-VDSwitch -NumUplinkPorts 1 -Name $DS_PROD -Location $DataCenter

#Assign ESXi Host to DS 
Add-VDSwitchVMHost -vdswitch $DS_VSAN -vmhost $ESX1
Add-VDSwitchVMHost -vdswitch $DS_VSAN -vmhost $ESX2
Add-VDSwitchVMHost -vdswitch $DS_VSAN -vmhost $ESX3

Add-VDSwitchVMHost -vdswitch $DS_PROD -vmhost $ESX1
Add-VDSwitchVMHost -vdswitch $DS_PROD -vmhost $ESX2
Add-VDSwitchVMHost -vdswitch $DS_PROD -vmhost $ESX3

#Create a VDPort Group for the DS
Get-VDSwitch -Name $DS_VSAN| New-VDPortgroup -Name $DP_VSAN -NumPorts 8 
Get-VDSwitch -Name $DS_PROD| New-VDPortgroup -Name $DP_PROD -NumPorts 8

#Assign Physical NIC to DS Switch from ESXi Hosts- VSAN
$Physical_NIC_ESX1_VSAN = Get-VMHostNetworkAdapter -VMHost $ESX1 -Name "vmnic2"
$Physical_NIC_ESX2_VSAN = Get-VMHostNetworkAdapter -VMHost $ESX2 -Name "vmnic2"
$Physical_NIC_ESX3_VSAN = Get-VMHostNetworkAdapter -VMHost $ESX3 -Name "vmnic2"

#Assign Physical NIC to DS Switch from ESXi Hosts - PROD
$Physical_NIC_ESX1_PROD = Get-VMHostNetworkAdapter -VMHost $ESX1 -Name "vmnic3"
$Physical_NIC_ESX2_PROD = Get-VMHostNetworkAdapter -VMHost $ESX2 -Name "vmnic3"
$Physical_NIC_ESX3_PROD = Get-VMHostNetworkAdapter -VMHost $ESX3 -Name "vmnic3"

#Get the VMKernel Port Group
$VMKernel_ESX1 = Get-VMHostNetworkAdapter -VMHost $ESX1 -Name "vmk1"
$VMKernel_ESX2 = Get-VMHostNetworkAdapter -VMHost $ESX2 -Name "vmk1"
$VMKernel_ESX3 = Get-VMHostNetworkAdapter -VMHost $ESX3 -Name "vmk1"

#Assign VMKernel Port Group to Distribution Switch - Port Group -VSAN
Get-VDSwitch $DS_VSAN | Add-VDSwitchPhysicalNetworkAdapter -VMHostVirtualNic $VMKernel_ESX1 -VMHostPhysicalNic $Physical_NIC_ESX1_VSAN -VirtualNicPortgroup $DP_VSAN -Confirm:$false
Get-VDSwitch $DS_VSAN | Add-VDSwitchPhysicalNetworkAdapter -VMHostVirtualNic $VMKernel_ESX2 -VMHostPhysicalNic $Physical_NIC_ESX2_VSAN -VirtualNicPortgroup $DP_VSAN -Confirm:$false
Get-VDSwitch $DS_VSAN | Add-VDSwitchPhysicalNetworkAdapter -VMHostVirtualNic $VMKernel_ESX3 -VMHostPhysicalNic $Physical_NIC_ESX3_VSAN -VirtualNicPortgroup $DP_VSAN -Confirm:$false

#Assign Physical NIC to DS-PROD
Get-VDSwitch $DS_PROD | Add-VDSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $Physical_NIC_ESX1_PROD -Confirm:$false
Get-VDSwitch $DS_PROD | Add-VDSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $Physical_NIC_ESX2_PROD -Confirm:$false
Get-VDSwitch $DS_PROD | Add-VDSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $Physical_NIC_ESX3_PROD -Confirm:$false

#Enable VSAN
Get-Cluster | Set-Cluster -VsanEnabled:$true -VsanDiskClaimMode Automatic -Confirm:$false -ErrorAction SilentlyContinue -Verbose 