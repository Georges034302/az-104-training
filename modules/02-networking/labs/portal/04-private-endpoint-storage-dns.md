# Lab: Private Endpoint to Storage + Private DNS (Minimal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a VNet, storage account, private endpoint to blob, and private DNS zone link. Validate storage name resolves to private IP (conceptual).

## What you will build
```mermaid
flowchart LR
  Client[VM/App in VNet] --> DNS[Private DNS Zone Link]
  DNS --> PE[Private Endpoint IP]
  PE --> Storage[Storage Account Blob]
```

## Estimated time
45–60 minutes

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
LAB="m02-pe-dns"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

source .env
echo "Environment loaded: RG_NAME=$RG_NAME, LOCATION=$LOCATION"
```

## Portal solution (high-level)
- Portal → Create VNet + subnet for private endpoint.
- Portal → Create Storage account.
- Storage → Networking → Private endpoint connections → Add.
- Create/choose Private DNS zone `privatelink.blob.core.windows.net` and link to VNet.
- Validate private endpoint connection state.



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