# Lab: ACR Build + ACI Run Container (Minimal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create an ACR, build a tiny container image using ACR Tasks, and run it in ACI. Capture login server and container FQDN.

## What you will build
```mermaid
flowchart LR
  Code[Dockerfile] --> ACR[ACR Build Task] --> Image[Image]
  Image --> ACI[ACI Container Group] --> FQDN[FQDN/IP]
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
LAB="m04-acr-aci"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

source .env
echo "Environment loaded: RG_NAME=$RG_NAME, LOCATION=$LOCATION"
```

## Portal solution (high-level)
- Portal → Container registries → Create ACR.
- Use Tasks or local docker to build/push an image.
- Portal → Container instances → Create using image from ACR.
- Validate container state is Running and view logs.



## Cleanup (required)
```bash
# Delete the resource group and all its resources asynchronously
az group delete \
  --name "$RG_NAME" \
  --yes \
  --no-wait
echo "Deleted RG: $RG_NAME (async)"

# Remove the app directory and environment file
rm -rf app .env
echo "Cleaned up app directory and environment file"
```

## Notes
- Every CLI command that returns an ID/URL is captured into a **variable** and echoed.
- If a command returns JSON, use `--query ... -o tsv` for clean variable assignment.