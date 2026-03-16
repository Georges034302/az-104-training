# Lab: Deploy App Service (Web App) + App Settings
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create an App Service Plan + Web App and configure an app setting. Capture the web app URL.

## What you will build
```mermaid
flowchart LR
  Client --> Web[Web App]
  Web --> Settings[App Settings]
  Plan[App Service Plan] --> Web
```

## Estimated time
35–50 minutes

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
LAB="m04-appsvc"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

source .env
echo "Environment loaded: RG_NAME=$RG_NAME, LOCATION=$LOCATION"
```

## Portal solution (high-level)
- Portal → App Services → Create Web App.
- Create new App Service Plan (Basic or Free where available).
- After deployment: Web App → Configuration → add app setting.
- Browse the default page to validate URL.



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