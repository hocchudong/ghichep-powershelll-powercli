$Telegramtoken = "1117214915:AAF4LFh6uChng056_oTyM6cz9TY4dyAn3YU"
$Telegramchatid = "717154123"

Function Send-Telegram {
Param([Parameter(Mandatory=$true)][String]$Message)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($Telegramtoken)/sendMessage?chat_id=$($Telegramchatid)&text=$($Message)"}


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


$StartTime = Get-Date
$verboseLogFile = "C:\Nested\mylogfile.log"

$VCSAInstallerPath = "C:\VCFLAB\Tools\VMware-VCSA-all-7.0.1-17956102"
$VIServer = "vc.hcdlab.local"
$VIUsername = "administrator@vsphere.local"
$VIPassword = "Homelab@2020"

# General Deployment Configuration for Nested ESXi, VCSA & NSX VMs
$VMDatacenter = "HCD-DC01"
$VMCluster = "HCD-Cluster02"
$VMNetwork = "dvpg-vlan-20"
$VMDatastore = "datastore3-r620"
$VMNetmask = "255.255.255.0"
$VMGateway = "192.168.20.1"
$VMDNS = "192.168.20.5"
$VMNTP = "192.168.20.72"
$VMPassword = "VMware1!"
$VMDomain = "nsxtlab.local"
$VMSyslog = "192.168.20.212"
$VMFolder = "Vsan-lab"
# Applicable to Nested ESXi only
$VMSSH = "true"
$VMVMFS = "false"

# VCSA Deployment Configuration
$VCSADeploymentSize = "tiny"
$VCSADisplayName = "vcsa"
$VCSAIPAddress = "192.168.20.80"
$VCSAHostname = "vcsa.nsxtlab.local" #Change to IP if you don't have valid DNS
$VCSAPrefix = "24"
$VCSASSODomainName = "vsphere.local"
$VCSASSOPassword = "VMware1!"
$VCSARootPassword = "VMware1!"
$VCSASSHEnable = "true"

$vcenter = Connect-VIServer $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue


$config = (Get-Content -Raw "$($VCSAInstallerPath)\vcsa-cli-installer\templates\install\embedded_vCSA_on_VC.json") | convertfrom-json


$config.'new_vcsa'.vc.hostname = $VIServer
$config.'new_vcsa'.vc.username = $VIUsername
$config.'new_vcsa'.vc.password = $VIPassword
$config.'new_vcsa'.vc.deployment_network = $VMNetwork
$config.'new_vcsa'.vc.datastore = $VMDatastore
$config.'new_vcsa'.vc.datacenter = $VMDatacenter
$config.'new_vcsa'.vc.target = $VMCluster
$config.'new_vcsa'.appliance.thin_disk_mode = $true
$config.'new_vcsa'.appliance.deployment_option = $VCSADeploymentSize
$config.'new_vcsa'.appliance.name = $VCSADisplayName
$config.'new_vcsa'.network.ip_family = "ipv4"
$config.'new_vcsa'.network.mode = "static"
$config.'new_vcsa'.network.ip = $VCSAIPAddress
$config.'new_vcsa'.network.dns_servers[0] = $VMDNS
$config.'new_vcsa'.network.prefix = $VCSAPrefix
$config.'new_vcsa'.network.gateway = $VMGateway
$config.'new_vcsa'.os.ntp_servers = $VMNTP
$config.'new_vcsa'.network.system_name = $VCSAHostname
$config.'new_vcsa'.os.password = $VCSARootPassword

if($VCSASSHEnable -eq "true") {
      $VCSASSHEnableVar = $true
  } else {
      $VCSASSHEnableVar = $false
  }
$config.'new_vcsa'.os.ssh_enable = $VCSASSHEnableVar
$config.'new_vcsa'.sso.password = $VCSASSOPassword
$config.'new_vcsa'.sso.domain_name = $VCSASSODomainName

#Send-Telegram -Message "Bat dau cai dat VCSA" 
My-Logger "Tao file JSON de cai dat VCSA"
$config | ConvertTo-Json | Set-Content -Path "$($ENV:Temp)\jsontemplate.json"

My-Logger "Cai dat VCSA."
Invoke-Expression "$($VCSAInstallerPath)\vcsa-cli-installer\win32\vcsa-deploy.exe install --no-esx-ssl-verify --accept-eula --acknowledge-ceip $($ENV:Temp)\jsontemplate.json"| Out-File -Append -LiteralPath $verboseLogFile

$EndTime = Get-Date
$duration = [math]::Round((New-TimeSpan -Start $StartTime -End $EndTime).TotalMinutes,2)

My-Logger "Da tao xong VM!"
My-Logger "Bat dau vao luc: $StartTime"
My-Logger "Ket thuc vao luc: $EndTime"
My-Logger "Tong thoi gian tao: $duration minutes"

#Send-Telegram -Message "Da ket thuc luc $EndTime, Tong thoi gian: $duration minutes" 

Read-Host -Prompt "An ENTER de thoat"