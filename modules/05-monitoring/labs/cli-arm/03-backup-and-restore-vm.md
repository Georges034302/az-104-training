# Lab: Backup a VM and Validate Restore Path (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough included for restore validation step).

## Objective
Create a VM and Recovery Services vault, enable VM backup using policy-based protection, and verify recoverability with a controlled restore test path.

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

## Setup: create environment file
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

az backup protection enable-for-vm \
  --resource-group "$RG_NAME" \
  --vault-name "$VAULT_NAME" \
  --vm "$VM_NAME" \
  --policy-name DefaultPolicy

echo "Backup protection enabled for VM: $VM_NAME"
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
```

### 4) Restore-path validation (Portal step)
```bash
echo "Portal step required: Recovery Services vault > Backup items > Azure Virtual Machine > $VM_NAME"
echo "Run Restore VM or Restore Disks to validate recoverability workflow."
echo "Use a new target name/resource to avoid impacting source VM."
```

## ARM template solution (optional)
You can codify vault creation and policy baseline in ARM/Bicep. Keep restore validation as an operator-run exercise for AZ-104 readiness.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- Ingestion and backup job completion are asynchronous; allow time before expecting recovery points.
- Backup and disaster recovery are different controls. This lab validates backup recoverability only.