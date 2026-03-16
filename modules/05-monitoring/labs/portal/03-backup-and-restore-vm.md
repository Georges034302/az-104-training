# Lab: Backup a VM + Restore Test (Recovery Services Vault)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a VM, create a Recovery Services Vault, enable VM backup using a policy, then perform a restore test (restore to a new VM is recommended).

## What you will build
```mermaid
flowchart LR
  VM --> Vault[Recovery Services Vault]
  Vault --> Policy[Backup Policy]
  Policy --> RP[Recovery Point]
  Restore --> NewVM[Restored VM]
```

## Estimated time
75–120 minutes

## Cost + safety
- All resources are created in a **dedicated Resource Group** for this lab and can be deleted at the end.
- Default region: **australiaeast** (change if needed).

## Prerequisites
- Azure subscription with permission to create resources
- Azure CLI installed and authenticated (`az login`)
- (Optional) Azure Portal access

## Setup: Create environment file
```bash
cat > .env << 'EOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m05-backup"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

source .env
echo "Environment loaded: RG_NAME=$RG_NAME, LOCATION=$LOCATION"
```

## Portal solution (high-level)
- Portal → Create a small VM.
- Portal → Recovery Services vaults → Create vault.
- Vault → Backup → Azure → Virtual machine → Select VM → Enable backup (choose default policy).
- Wait for first backup (or trigger) then test Restore (restore to a new VM).
- Validate restored VM exists (then delete it during cleanup).



## Cleanup (required)
```bash
# Delete the resource group and all its resources asynchronously
az group delete \
  --name "$RG_NAME" \
  --yes \
  --no-wait
echo "Deleted RG: $RG_NAME (async)"

# Remove the environment file
rm -f .env
echo "Cleaned up environment file"
```

## Notes
- Every CLI command that returns an ID/URL is captured into a **variable** and echoed.
- If a command returns JSON, use `--query ... -o tsv` for clean variable assignment.