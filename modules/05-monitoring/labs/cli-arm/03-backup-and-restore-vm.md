# Lab: Backup a VM and Validate Restore Path (CLI + ARM)
> Variant: CLI + ARM lab track with one **portal-assisted restore validation** step to keep the recovery test safe and easy to verify.

## Objective
Create a VM and Recovery Services vault, enable VM backup using policy-based protection, and verify recoverability with a controlled restore-validation workflow.

## What you will build

 [Azure VM]
    |
    v
 [Recovery Services Vault]
    |
    v
 [Backup Policy + Recovery Points]
    |
    v
 [Restore Validation]

## Estimated time
80-120 minutes

## Cost + safety
- Backup storage consumption increases with recovery points and retention.
- Keep VM size small for lab cost control.
- Delete restored artifacts after validation to avoid unnecessary charges.

## Prerequisites
- Azure subscription with rights to create VM and Recovery Services resources
- Azure CLI installed and authenticated with `az login`
- Azure Portal access for restore wizard validation

## Setup: Create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m05backup"
RG_NAME="${PREFIX}-${LAB}-rg"
VM_NAME="${PREFIX}-${LAB}-vm"
VAULT_NAME="${PREFIX}-${LAB}-rsv"
ADMIN_USER="azureuser"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, VM_NAME=$VM_NAME, VAULT_NAME=$VAULT_NAME"
```

## Azure CLI solution (fully parameterized)
### 1) Create VM and vault
```bash
az group create --name "$RG_NAME" --location "$LOCATION"

VM_ID="$(az vm create \
  --resource-group "$RG_NAME" \
  --name "$VM_NAME" \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username "$ADMIN_USER" \
  --generate-ssh-keys \
  --query id -o tsv)"

VAULT_ID="$(az backup vault create \
  --resource-group "$RG_NAME" \
  --name "$VAULT_NAME" \
  --location "$LOCATION" \
  --query id -o tsv)"

echo "VM_ID=$VM_ID"
echo "VAULT_ID=$VAULT_ID"
```

### 2) Configure vault and enable VM protection
```bash
az backup vault backup-properties set \
  --resource-group "$RG_NAME" \
  --vault-name "$VAULT_NAME" \
  --backup-storage-redundancy LocallyRedundant

# DefaultPolicy is the built-in daily VM backup policy created with a new Recovery Services vault.
# It is suitable for this lab unless you are intentionally testing a custom policy.
az backup protection enable-for-vm \
  --resource-group "$RG_NAME" \
  --vault-name "$VAULT_NAME" \
  --vm "$VM_NAME" \
  --policy-name DefaultPolicy

echo "Backup protection enabled for VM: $VM_NAME using DefaultPolicy"
```

### 3) Validate backup registration
```bash
az backup vault show \
  --resource-group "$RG_NAME" \
  --name "$VAULT_NAME" \
  --query "{name:name,location:location,provisioningState:properties.provisioningState}" -o jsonc

az backup item list \
  --resource-group "$RG_NAME" \
  --vault-name "$VAULT_NAME" \
  --backup-management-type AzureIaasVM \
  --workload-type VM \
  -o table

# Backup jobs are asynchronous. If the first recovery point is not visible yet,
# wait a few minutes and check the job state again.
az backup job list \
  --resource-group "$RG_NAME" \
  --vault-name "$VAULT_NAME" \
  -o table
```

### 4) Restore-path validation (portal-assisted, safest verification path)
```bash
echo "Open Azure Portal > Recovery Services vaults > $VAULT_NAME"
echo "Select Backup items > Azure Virtual Machine > $VM_NAME"
echo "Choose Restore VM or Restore Disks to validate the recoverability workflow"
echo "Use a new target name or alternate resource placement to avoid impacting the source VM"
```

## ARM template solution (optional)
You can codify vault creation and policy baseline in ARM/Bicep. Keep restore validation as an operator-run exercise for AZ-104 readiness.

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
- Ingestion and backup job completion are asynchronous; allow time before expecting recovery points.
- Backup and disaster recovery are different controls. This lab validates backup recoverability only.