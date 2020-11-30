Connect-AzAccount

# General variables
$location = "UKSouth"                                               # Azure Region for resources to be built into
$RGName = "HiggCon"                                                 # Resource group name
$VNet = "PackagingVNET"                                             # Environment Virtual Network name
$NsgName = "PackagingNSG"                                           # Network Security Group name (firewall)

# Storage account and container names
$StorAccRequired = $true                                            # Specifies if a Storage Account and Container should be created
$StorAcc = "packagingstoracc"                                       # Storage account name (if used)
$ContainerName = "data"                                             # Storage container name (if used)
$ContainerScripts = "C:\Temp\PackagingVM\Config"                    # All files in this path will be copied up to the Storage Account Container, so available to be run on the remote VMs

# VM Admin Account
$password = ConvertTo-SecureString “Password1234” -AsPlainText -Force                       # Local Admin Password for VMs 
$VMCred = New-Object System.Management.Automation.PSCredential (“AppPackager”, $password)   # Local Admin User for VMs

# VM Count and Name
$NumberofVMs = 1                                                    # Specify number of VMs to be provisioned
$VmNamePrefix = "PVMMSI"                                            # Specifies the first part of the VM name (usually alphabetic)
$VmNumberStart = 500                                                # Specifies the second part of the VM name (usually numeric)
$VmSize = "Standard_B2s"                                            # Specifies Azure Size to use for the VM
$VmImage = "MicrosoftWindowsDesktop:Windows-10:20h2-ent:latest"     # Specifies the Publisher, Offer, SKU and Version of the image to be used to provision the VM
$VmShutdown = $true                                                 # Specifies if the newly provisioned VM should be shutdown (can save costs)

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"                          # Turns off Breaking Changes warnings for Cmdlets

#=======================================================================================================================================================

function ConfigureNetwork {
    $virtualNetwork = New-AzVirtualNetwork -ResourceGroupName $RGName -Location $Location -Name $VNet -AddressPrefix 10.0.0.0/16
    $subnetConfig = Add-AzVirtualNetworkSubnetConfig -Name default -AddressPrefix 10.0.0.0/24 -VirtualNetwork $virtualNetwork
        
    $rule1 = New-AzNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $RGName -Location $location -Name $NsgName -SecurityRules $rule1      # $Rule1, $Rule2 etc. 
        If ($nsg.ProvisioningState -eq "Succeeded") {Write-Host "Network Security Group created successfully"}Else{Write-Host "*** Unable to create or configure Network Security Group! ***"}
    $Vnsc = Set-AzVirtualNetworkSubnetConfig -Name default -VirtualNetwork $virtualNetwork -AddressPrefix "10.0.1.0/24" -NetworkSecurityGroup $nsg
    $virtualNetwork | Set-AzVirtualNetwork >> null
        If ($virtualNetwork.ProvisioningState -eq "Succeeded") {Write-Host "Virtual Network created and associated with the Network Security Group successfully"}Else{Write-Host "*** Unable to create the Virtual Network, or associate it to the Network Security Group! ***"}
}

function CreateStorageAccount {
    If ($StorAccRequired -eq $True)
        {
        $storageAccount = New-AzStorageAccount -ResourceGroupName $RGName -AccountName $StorAcc -Location uksouth -SkuName Standard_LRS
        $ctx = $storageAccount.Context
        $Container = New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission Container
        If ($storageAccount.StorageAccountName -eq $StorAcc -and $Container.Name -eq $ContainerName) {Write-Host "Storage Account and container created successfully"}Else{Write-Host "*** Unable to create the Storage Account or container! ***"}    
        #$BlobUpload = Set-AzStorageBlobContent -File $BlobFilePath -Container $ContainerName -Blob $Blob -Context $ctx 
        Get-ChildItem -Path $ContainerScripts -File -Recurse | Set-AzStorageBlobContent -Container "data" -Context $ctx
        }
        Else
        {
            Write-Host "Creation of Storage Account and Storage Container not required"
        }   
}


function CreateVMp($VMName) {
    $PublicIpAddressName = $VMName + "-ip"

    $Params = @{
    ResourceGroupName = $RGName
    Name = $VMName
    Size = $VmSize
    Location = $Location
    VirtualNetworkName = $VNet
    SubnetName = "default"
    SecurityGroupName = $NsgName
    PublicIpAddressName = $PublicIpAddressName
    ImageName = $VmImage
    Credential = $VMCred
    }

    $VMCreate = New-AzVm @Params
    If ($VMCreate.ProvisioningState -eq "Succeeded") {Write-Host "Virtual Machine $VMName created successfully"}Else{Write-Host "*** Unable to create Virtual Machine $VMName! ***"}
}

function RunVMConfig($VMName, $BlobFilePath, $Blob) {

    $Params = @{
    ResourceGroupName = $RGName
    VMName = $VMName
    Location = $Location
    FileUri = $BlobFilePath
    Run = $Blob
    Name = "ConfigureVM"
    }

    $VMConfigure = Set-AzVMCustomScriptExtension @Params
    If ($VMConfigure.IsSuccessStatusCode -eq $True) {Write-Host "Virtual Machine $VMName configured successfully"}Else{Write-Host "*** Unable to configure Virtual Machine $VMName! ***"}
}

#=======================================================================================================================================================

# Main Script

# Create Resource Group
$RG = New-AzResourceGroup -Name $RGName -Location $Location
If ($RG.ResourceGroupName -eq $RGName) {Write-Host "Resource Group created successfully"}Else{Write-Host "*** Unable to create Resource Group! ***"}

# Create VNet, NSG and rules (Comment out if not required)
ConfigureNetwork

# Create Storage Account and copy media (Comment out if not required)
CreateStorageAccount

# Build VM/s
$Count = 1
While ($Count -le $NumberOfVMs)
    {
    Write-Host "Creating and configuring $Count of $NumberofVMs VMs"
    $VM = $VmNamePrefix + $VmNumberStart
    CreateVMp "$VM"
    RunVMConfig "$VM" "https://packagingstoracc.blob.core.windows.net/data/VMConfig.ps1" "VMConfig.ps1"
    # Shutdown VM if $VmShutdown is true
    If ($VmShutdown)
        {
        $Stopvm = Stop-AzVM -ResourceGroupName $RGName -Name $VM -Force
        If ($RG.ResourceGroupName -eq $RGName) {Write-Host "VM $VM shutdown successfully"}Else{Write-Host "*** Unable to shutdown VM $VM! ***"}
        }
    $Count++
    $VmNumberStart++
    }
