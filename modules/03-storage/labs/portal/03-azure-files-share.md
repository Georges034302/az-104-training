# Lab: Azure Files Share (Create + Quota)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a storage account and an Azure Files share with quota. (Mounting is optional and depends on client network access to port 445.)

## What you will build
```mermaid
flowchart LR
  Storage --> Share[File Share]
  Client --> SMB[SMB 445] --> Share
```

## Estimated time
25–40 minutes

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
LAB="m03-files"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

source .env
echo "Environment loaded: RG_NAME=$RG_NAME, LOCATION=$LOCATION"
```

## Portal solution (high-level)
- Portal → Storage account → File shares → Create file share.
- Set a quota (e.g., 5 GB).
- Copy the connection string/mount path for later use.



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