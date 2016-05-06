#creating a new vm from image template.
#This script using a NIC and an IP address already deployed.

#input parameters
$sourceImageUri = Read-Host "Template imageUri"
$adminUsername = Read-Host "adminUsername"
$adminPassword = Read-Host "password of adminUsername"
$vmName = Read-Host "vm name"
$domName = Read-Host "domain name"


# Authenticate against Azure and cache subscription data
Login-AzureRmAccount

# Switch subscription
Get-AzureRMSubscription | Out-GridView -PassThru | Select-AzureRmSubscription

# Get the storage account
$storageAccount = Get-AzureRmStorageAccount | Out-GridView -PassThru

if(-not $storageAccount) {  
    throw "Unable to find storage account '$storageAccountName'. Cannot continue."
}

# Enable verbose output and stop on error
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'

# some reserved script variables
$resourceGroupName = $storageAccount.ResourceGroupName
$location = $storageAccount.Location


$vmSize = Get-AzureRmVMSize -Location $location | Out-GridView -PassThru
$nic = Get-AzureRmNetworkInterface -ResourceGroupName $resourceGroupName | Out-GridView -PassThru
$ip = Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroupName | Out-GridView -PassThru
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName | Out-GridView -PassThru

# Specify the VM name and size
Write-Verbose 'Creating VM Config'  
$vm = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize.Name

# Specify local administrator account, and then add the NIC
$cred = New-Object PSCredential $adminUsername, ($adminPassword | ConvertTo-SecureString -AsPlainText -Force) # you could use Get-Credential instead to get prompted
# NOTE: if you are deploying a Linux machine, replace the -Windows switch with a -Linux switch.
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

# Specify the OS disk
$diskName = 'osdisk'
$osDiskUri = '{0}vhds/{1}{2}.vhd' -f $storageAccount.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $diskName
# NOTE: if you are deploying a Linux machine, replace the -Windows switch with a -Linux switch.
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $sourceImageUri -Windows

Write-Verbose 'Creating VM...'  
$result = New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm

if($result.Status -eq 'Succeeded') {  
    $result
    Write-Verbose ('VM named ''{0}'' is now ready, you can connect using username: {1} and password: {2}' -f $vmName, $adminUsername, $adminPassword)
} else {
    $result
    Write-Error 'Virtual machine was not created successfully.'
}