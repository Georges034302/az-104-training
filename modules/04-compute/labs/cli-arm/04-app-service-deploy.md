# Lab: Deploy App Service and Configuration (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Create an App Service plan and web app, configure application settings, deploy a simple static payload, and validate hostname and settings.

## What you will build

 [Client]
    |
    v
 [Web App]
    |
    +--> [App Settings]
    +--> [Deployment Content]
    |
    v
 [App Service Plan]

## Estimated time
35-50 minutes

## Cost + safety
- App Service Plan tier controls cost and capability.
- Keep the lab at small plan size and cleanup after validation.

## Prerequisites
- Azure subscription with rights to create App Service resources
- Azure CLI installed and authenticated with az login
- zip command available in shell

## Setup: Create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m04appsvc"
RG_NAME="${PREFIX}-${LAB}-rg"
PLAN_NAME="${PREFIX}-${LAB}-plan"
RUNTIME="NODE|20-lts"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, PLAN_NAME=$PLAN_NAME"
```

## Azure CLI solution (fully parameterized)
### 1) Create resource group and plan
```bash
az group create --name "$RG_NAME" --location "$LOCATION"

WEBAPP_NAME="$(echo "${PREFIX}${LAB}$(openssl rand -hex 3)" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-60)"

az appservice plan create \
  --resource-group "$RG_NAME" \
  --name "$PLAN_NAME" \
  --location "$LOCATION" \
  --sku B1 \
  --is-linux
```

### 2) Create web app and configure settings
```bash
WEBAPP_ID="$(az webapp create \
  --resource-group "$RG_NAME" \
  --plan "$PLAN_NAME" \
  --name "$WEBAPP_NAME" \
  --runtime "$RUNTIME" \
  --query id -o tsv)"

az webapp config appsettings set \
  --resource-group "$RG_NAME" \
  --name "$WEBAPP_NAME" \
  --settings DEMO_SETTING="az104" ENVIRONMENT="lab"

mkdir -p site
cat > site/index.html << 'HTMLEOF'
<html><body><h1>AZ-104 App Service Lab</h1><p>Compute module deployment succeeded.</p></body></html>
HTMLEOF

cd site && zip -r ../site.zip . && cd - >/dev/null

az webapp deploy \
  --resource-group "$RG_NAME" \
  --name "$WEBAPP_NAME" \
  --src-path site.zip \
  --type zip

WEBAPP_URL="$(az webapp show \
  --resource-group "$RG_NAME" \
  --name "$WEBAPP_NAME" \
  --query defaultHostName -o tsv)"

echo "WEBAPP_ID=$WEBAPP_ID"
echo "WEBAPP_URL=https://$WEBAPP_URL"
```

### 3) Validate
```bash
az webapp config appsettings list \
  --resource-group "$RG_NAME" \
  --name "$WEBAPP_NAME" \
  --query "[].{name:name,value:value}" \
  -o table

curl -I "https://$WEBAPP_URL"
```

## ARM template solution (when needed)
Optional. App Service is commonly deployed with ARM/Bicep in production pipelines, but this lab focuses on operational CLI deployment and validation.

## Cleanup (required)
```bash
# Delete the resource group and all resources asynchronously
az group delete --name "$RG_NAME" --yes --no-wait
echo "Deleted RG: $RG_NAME (async)"

# Remove local lab files
rm -f .env site.zip
rm -rf site
echo "Cleaned up local lab files"
```

## Notes
- App names must be globally unique.
- Scaling in App Service applies at plan level, not per-app in isolation.