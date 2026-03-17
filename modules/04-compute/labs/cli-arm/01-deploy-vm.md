# Lab: Deploy a Linux VM with VNet and NSG (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Deploy a Linux VM in a dedicated subnet, secure inbound SSH with an NSG rule, capture the public endpoint, and validate compute and network state.

## What you will build

 [Client IP]
      |
      v
 [NSG Allow SSH 22]
      |
      v
 [Subnet]
      |
      v
 [NIC] ---> [Linux VM]
              |
              v
           [Public IP]

## Estimated time
45-60 minutes

## Cost + safety
- All resources are deployed into one lab resource group for complete cleanup.
- Restrict SSH source CIDR whenever possible. Do not leave management ports open to the internet in real environments.

## Prerequisites
- Azure subscription with rights to create compute and network resources
- Azure CLI installed and authenticated with az login

## Setup: Create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m04vm"
RG_NAME="${PREFIX}-${LAB}-rg"
VNET_NAME="${PREFIX}-${LAB}-vnet"
SUBNET_NAME="vm"
NSG_NAME="${PREFIX}-${LAB}-nsg"
VM_NAME="${PREFIX}-${LAB}-vm"
ADMIN_USER="azureuser"
VM_SIZE="Standard_B1s"
VM_IMAGE="Ubuntu2204"
VNET_CIDR="10.60.0.0/16"
SUBNET_CIDR="10.60.2.0/24"
SSH_SOURCE_CIDR="0.0.0.0/0"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, VM_NAME=$VM_NAME"
```

## Azure CLI solution (fully parameterized)
### 1) Create resource group and network
```bash
az group create --name "$RG_NAME" --location "$LOCATION"

az network vnet create \
  --resource-group "$RG_NAME" \
  --name "$VNET_NAME" \
  --address-prefixes "$VNET_CIDR" \
  --subnet-name "$SUBNET_NAME" \
  --subnet-prefixes "$SUBNET_CIDR"

NSG_ID="$(az network nsg create \
  --resource-group "$RG_NAME" \
  --name "$NSG_NAME" \
  --query NewNSG.id -o tsv)"

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name "$NSG_NAME" \
  --name "Allow-SSH" \
  --priority 1000 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "$SSH_SOURCE_CIDR" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 22

az network vnet subnet update \
  --resource-group "$RG_NAME" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_NAME" \
  --network-security-group "$NSG_ID"
```

### 2) Deploy the VM
```bash
VM_ID="$(az vm create \
  --resource-group "$RG_NAME" \
  --name "$VM_NAME" \
  --image "$VM_IMAGE" \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --vnet-name "$VNET_NAME" \
  --subnet "$SUBNET_NAME" \
  --nsg "" \
  --public-ip-sku Standard \
  --generate-ssh-keys \
  --query id -o tsv)"

VM_PUBLIC_IP="$(az vm show \
  --resource-group "$RG_NAME" \
  --name "$VM_NAME" \
  -d --query publicIps -o tsv)"

echo "VM_ID=$VM_ID"
echo "VM_PUBLIC_IP=$VM_PUBLIC_IP"
```

### 3) Validate
```bash
az vm get-instance-view \
  --resource-group "$RG_NAME" \
  --name "$VM_NAME" \
  --query "instanceView.statuses[].displayStatus" \
  -o table

az network vnet subnet show \
  --resource-group "$RG_NAME" \
  --vnet-name "$VNET_NAME" \
  --name "$SUBNET_NAME" \
  --query "{subnet:name,nsg:networkSecurityGroup.id,addressPrefix:addressPrefix}" \
  -o table
```

## ARM template solution (when needed)
Not required for this lab. The primary learning objective is operational VM deployment and validation via CLI.

## Cleanup (required)
```bash
# Delete the resource group and all resources asynchronously
az group delete --name "$RG_NAME" --yes --no-wait
echo "Deleted RG: $RG_NAME (async)"

# Remove local lab files
rm -f .env
echo "Cleaned up local lab files"
```

## Notes
- VM stop and VM deallocate are different cost states. Use deallocate to stop compute billing.
- In production, set SSH_SOURCE_CIDR to your public IP range instead of 0.0.0.0/0.