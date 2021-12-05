# Cong TO
# Script add cac host ESXi vao vCenter

$StartTime = Get-Date

$Telegramtoken = "1117214915:AAF4LFh6uChng056_oTyM6cz9TY4dyAn3YU"
$Telegramchatid = "717154123"

Function Send-Telegram {
Param([Parameter(Mandatory=$true)][String]$Message)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Response = Invoke-RestMethod -Uri "https://api.telegram.org/bot$($Telegramtoken)/sendMessage?chat_id=$($Telegramchatid)&text=$($Message)"}


$verboseLogFile = "mylogfile.log"

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


$VIServer = "vcsa.vsanlab.local"
$VIUsername = "administrator@vsphere.local"
$VIPassword = "VMware1!"

Disconnect-VIServer *
$VCSA = Connect-VIServer -Server $VIServer -User $VIUsername -Password $VIPassword -WarningAction SilentlyContinue
# Disconnect-VIServer * 

$DataCenter = "MYLAB"
$Cluster = "MYLAB-CLUSTER"

#New Data Center
My-Logger "Tao DataCenter"
New-Datacenter -Location (Get-Folder -NoRecursion) -Name $DataCenter

#New Cluster without HA & DRS enabled 
My-Logger "Tao Cluster"
New-Cluster -Location $DataCenter -Name $Cluster

#Add Hosts to Cluster
My-Logger "Add cac host vao Vcenter"
Add-VMHost vesxi-191.vsanlab.local -location $Cluster -user root -password VMware1! -force:$true
Add-VMHost vesxi-192.vsanlab.local -location $Cluster -user root -password VMware1! -force:$true
Add-VMHost vesxi-193.vsanlab.local -location $Cluster -user root -password VMware1! -force:$true


Send-Telegram -Message "Da tao xong Cluser va add cac host ESXi"
#Enable SSH 
#Start SSH for Host
# Start-VMHostService -HostService (Get-VMHost | Get-VMHostService | Where { $_.Key -eq “TSM-SSH” } )

#Supress SSH Warning
# Get-VMHost | Get-AdvancedSetting UserVars.SuppressShellWarning |Set-AdvancedSetting -Value 1

# Get-Datastore -Name Datastore1 | Set-Datastore -Name LOCAL_ESX1
# Get-Datastore -Name "Datastore1 (1)" | Set-Datastore -Name LOCAL_ESX2
# Get-Datastore -Name "Datastore1 (2)" | Set-Datastore -Name LOCAL_ESX3