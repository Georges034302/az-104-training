# Lab: VM Availability with Availability Set (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Deploy two Linux VMs in one availability set so they are distributed across fault and update domains, then validate availability-set membership.

## What you will build

 [Availability Set]
      |
      +--> [VM1]
      |
      +--> [VM2]
      |
      +--> [Fault Domains]
      +--> [Update Domains]

## Estimated time
45-60 minutes

## Cost + safety
- This lab deploys two VMs, which can incur more cost than a single-VM lab.
- Keep VM size small and clean up immediately when finished.

## Prerequisites
- Azure subscription with rights to create compute and network resources
- Azure CLI installed and authenticated with az login

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m04avail"
RG_NAME="${PREFIX}-${LAB}-rg"
AS_NAME="${PREFIX}-${LAB}-as"
VM1_NAME="${PREFIX}-${LAB}-vm1"
VM2_NAME="${PREFIX}-${LAB}-vm2"
ADMIN_USER="azureuser"
VM_SIZE="Standard_B1s"
VM_IMAGE="Ubuntu2204"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, AS_NAME=$AS_NAME"
```

## Azure CLI solution (fully parameterized)
### 1) Create resource group and availability set
```bash
az group create --name "$RG_NAME" --location "$LOCATION"

AS_ID="$(az vm availability-set create \
  --resource-group "$RG_NAME" \
  --name "$AS_NAME" \
  --location "$LOCATION" \
  --platform-fault-domain-count 2 \
  --platform-update-domain-count 5 \
  --sku Aligned \
  --query id -o tsv)"

echo "AS_ID=$AS_ID"
```

### 2) Deploy two VMs in the availability set
```bash
VM1_ID="$(az vm create \
  --resource-group "$RG_NAME" \
  --name "$VM1_NAME" \
  --image "$VM_IMAGE" \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --generate-ssh-keys \
  --availability-set "$AS_NAME" \
  --query id -o tsv)"

VM2_ID="$(az vm create \
  --resource-group "$RG_NAME" \
  --name "$VM2_NAME" \
  --image "$VM_IMAGE" \
  --size "$VM_SIZE" \
  --admin-username "$ADMIN_USER" \
  --generate-ssh-keys \
  --availability-set "$AS_NAME" \
  --query id -o tsv)"

echo "VM1_ID=$VM1_ID"
echo "VM2_ID=$VM2_ID"
```

### 3) Validate
```bash
az vm availability-set show \
  --resource-group "$RG_NAME" \
  --name "$AS_NAME" \
  --query "{faultDomains:platformFaultDomainCount,updateDomains:platformUpdateDomainCount,vms:virtualMachines[].id}" \
  -o jsonc

az vm list \
  --resource-group "$RG_NAME" \
  --query "[].{name:name,availabilitySet:availabilitySet.id,powerState:powerState}" \
  -o table
```

## ARM template solution (when needed)
Not required for this lab. Availability concepts are validated through live deployment and inspection.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- A VM cannot be both zonal and placed in an availability set at the same time.
- If zone-level resilience is required, use zonal VMs plus zone-aware architecture instead of an availability set.