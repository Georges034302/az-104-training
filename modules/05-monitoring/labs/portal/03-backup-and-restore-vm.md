# Lab: Backup a VM and Validate Restore (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Protect a VM with Azure Backup using a Recovery Services vault, then validate recoverability through a controlled restore test.

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
 [Restore Validation Target]

## Estimated time
80-120 minutes

## Cost + safety
- Backup retention increases storage cost over time.
- Use a small VM and default policy for lab scope.
- Delete restored test resources after validation.

## Prerequisites
- Azure subscription with rights to create VM and backup resources
- Azure Portal access

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m05backup"
RG_NAME="${PREFIX}-${LAB}-rg"
VM_NAME="${PREFIX}-${LAB}-vm"
VAULT_NAME="${PREFIX}-${LAB}-rsv"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, VM_NAME=$VM_NAME, VAULT_NAME=$VAULT_NAME"
```

## Portal solution (step-by-step)
### 1) Create resource group and VM
1. Open Resource groups and create ${RG_NAME} in ${LOCATION}.
2. Open Virtual machines and create ${VM_NAME} in ${RG_NAME}.
3. Select Ubuntu Server 22.04 LTS and a small size for lab cost control.
4. Complete deployment.

### 2) Create Recovery Services vault
1. Open Recovery Services vaults and select Create.
2. Set:
  - Resource group: ${RG_NAME}
  - Vault name: ${VAULT_NAME}
  - Region: ${LOCATION}
3. Select Review + create, then Create.

### 3) Enable backup protection for VM
1. Open vault ${VAULT_NAME}.
2. Select Backup.
3. Set workload where running to Azure.
4. Set what do you want to backup to Virtual machine.
5. Select Backup.
6. In Select virtual machines, choose ${VM_NAME}.
7. Keep the default backup policy for lab scope.
8. Select Enable backup.

### 4) Trigger backup and monitor job
1. In vault, open Backup items > Azure Virtual Machine.
2. Select ${VM_NAME}.
3. Select Backup now.
4. Choose retention date (short lab retention is acceptable).
5. Track job completion in Backup jobs.

### 5) Validate restore path
1. In the same backup item, select Restore VM (or Restore Disks).
2. Choose the most recent recovery point.
3. Restore to a new target resource name to avoid affecting source VM.
4. Validate restore output resource creation.
5. Delete restored test resource after verification.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- Backup enablement is not equivalent to tested recoverability; restore testing is mandatory.
- Backup jobs and restore tasks are asynchronous and can require additional wait time.