# Lab: Private Endpoint for Storage + Private DNS (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Deploy a storage account, private endpoint, private DNS zone, and VNet link so blob endpoint resolution uses a private IP.

## What you will build

 [VNet + PE subnet] ---> [Private Endpoint NIC] ---> [Storage Account (Blob)]
           |
           v
 [Private DNS zone: privatelink.blob.core.windows.net]

## Estimated time
45-60 minutes

## Cost + safety
- All resources are grouped in one resource group for easy deletion.
- Storage and private endpoint generate small cost while active.

## Prerequisites
- Azure CLI authenticated (`az login`)
- Permission to create networking and storage resources

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m02-pe-dns"
RG_NAME="${PREFIX}-${LAB}-rg"
VNET_NAME="${PREFIX}-${LAB}-vnet"
PE_SUBNET_NAME="private-endpoints"
VNET_CIDR="10.50.0.0/16"
PE_SUBNET_CIDR="10.50.3.0/24"
PDNS_ZONE="privatelink.blob.core.windows.net"
ENVEOF

source .env
echo "Loaded: $RG_NAME, $VNET_NAME, $PDNS_ZONE"
```

## Azure CLI solution (fully parameterized)
### 1) Create resource group and VNet
```bash
az group create --name "$RG_NAME" --location "$LOCATION"

az network vnet create \
  --resource-group "$RG_NAME" \
  --name "$VNET_NAME" \
  --address-prefixes "$VNET_CIDR" \
  --subnet-name "$PE_SUBNET_NAME" \
  --subnet-prefixes "$PE_SUBNET_CIDR"
```

### 2) Create storage account
```bash
SUFFIX="$(openssl rand -hex 3)"
STG_NAME="$(echo "${PREFIX}${LAB//-/}${SUFFIX}" | tr -cd 'a-z0-9' | cut -c1-24)"

az storage account create \
  --name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2

STG_ID="$(az storage account show --name "$STG_NAME" --resource-group "$RG_NAME" --query id -o tsv)"
echo "STG_NAME=$STG_NAME"
echo "STG_ID=$STG_ID"
```

### 3) Create private DNS zone and VNet link
```bash
PDNS_ZONE_ID="$(az network private-dns zone create \
  --resource-group "$RG_NAME" \
  --name "$PDNS_ZONE" \
  --query id -o tsv)"

az network private-dns link vnet create \
  --resource-group "$RG_NAME" \
  --zone-name "$PDNS_ZONE" \
  --name "${PREFIX}-${LAB}-vnet-link" \
  --virtual-network "$VNET_NAME" \
  --registration-enabled false

echo "PDNS_ZONE_ID=$PDNS_ZONE_ID"
```

### 4) Create private endpoint and DNS zone group
```bash
PE_NAME="${PREFIX}-${LAB}-pe"

az network private-endpoint create \
  --resource-group "$RG_NAME" \
  --name "$PE_NAME" \
  --vnet-name "$VNET_NAME" \
  --subnet "$PE_SUBNET_NAME" \
  --private-connection-resource-id "$STG_ID" \
  --group-id blob \
  --connection-name "${PE_NAME}-conn"

az network private-endpoint dns-zone-group create \
  --resource-group "$RG_NAME" \
  --endpoint-name "$PE_NAME" \
  --name default \
  --private-dns-zone "$PDNS_ZONE_ID" \
  --zone-name "$PDNS_ZONE"
```

### 5) Validate
```bash
PE_NIC_ID="$(az network private-endpoint show \
  --resource-group "$RG_NAME" \
  --name "$PE_NAME" \
  --query "networkInterfaces[0].id" -o tsv)"

PE_IP="$(az network nic show --ids "$PE_NIC_ID" --query "ipConfigurations[0].privateIPAddress" -o tsv)"
echo "PE_IP=$PE_IP"

az network private-dns record-set a list \
  --resource-group "$RG_NAME" \
  --zone-name "$PDNS_ZONE" \
  -o table
```

## ARM template solution (when needed)
Not required for this lab. The CLI workflow is preferred here because private endpoint + DNS zone group orchestration is easier to validate step by step.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- Private networking does not replace data-plane authorization (RBAC/SAS/keys still apply).
- Validate DNS mapping to private IP before testing client connectivity.
