# Lab: Deploy App Service and App Settings (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create an App Service plan and web app, configure app settings, and validate the web endpoint.

## What you will build

 [Client]
   |
   v
 [Web App]
   |
   +--> [App Settings]
   +--> [Optional Slot]
   |
   v
 [App Service Plan]

## Estimated time
35-50 minutes

## Cost + safety
- Plan tier drives App Service cost and feature set.
- Keep to a small plan tier for lab scope.

## Prerequisites
- Azure subscription with rights to create App Service resources
- Azure Portal access

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m04appsvc"
RG_NAME="${PREFIX}-${LAB}-rg"
PLAN_NAME="${PREFIX}-${LAB}-plan"
APP_NAME="az104m04appsvc001"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, PLAN_NAME=$PLAN_NAME"
```

## Portal solution (step-by-step)
### 1) Create resource group
1. Open Resource groups and select Create.
2. Set name ${RG_NAME} and region ${LOCATION}.
3. Create the resource group.

### 2) Create web app and plan
1. Open App Services and select Create > Web App.
2. Set:
  - Resource group: ${RG_NAME}
  - Name: choose a globally unique app name based on ${APP_NAME}
  - Runtime stack: Node 20 LTS (or currently available equivalent)
  - Operating System: Linux
  - Region: ${LOCATION}
3. In App Service Plan:
  - Plan name: ${PLAN_NAME}
  - Pricing plan: B1 or smallest acceptable lab tier
4. Select Review + create, then Create.

### 3) Configure app settings
1. Open the web app resource.
2. Go to Settings > Environment variables (or Configuration, depending on portal view).
3. Add app settings:
  - DEMO_SETTING = az104
  - ENVIRONMENT = lab
4. Save changes and allow restart if prompted.

### 4) Optional slot step for safer deployments
1. Open Deployment slots.
2. Add slot named staging.
3. Keep this slot for future swap practice.

### 5) Validate
1. In Overview, copy the default domain URL.
2. Open the URL and confirm the app responds.
3. In Environment variables/Configuration, confirm both app settings exist.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- App settings are exposed as environment variables to the runtime.
- Scale actions apply to the App Service plan, which can affect every app in that plan.