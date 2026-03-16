# Lab: Service Health and Resource Health Alerts (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Create subscription-scoped Activity Log alerts for Service Health and Resource Health events and route both alerts to a shared Action Group.

## What you will build

 [Service Health Events] ------+
                              |
 [Resource Health Events] ----+--> [Activity Log Alert Rules] --> [Action Group] --> [Email Receiver]

## Estimated time
30-45 minutes

## Cost + safety
- Monitoring configuration only; no VM required.
- Use a dedicated resource group for easy cleanup.

## Prerequisites
- Azure subscription with permission to create monitor resources
- Azure CLI installed and authenticated with `az login`
- A valid email inbox for notification tests

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m05healthalerts"
RG_NAME="${PREFIX}-${LAB}-rg"
AG_NAME="${PREFIX}-${LAB}-ag"
ALERT_EMAIL="you@example.com"
SERVICE_ALERT_NAME="${PREFIX}-${LAB}-service"
RESOURCE_ALERT_NAME="${PREFIX}-${LAB}-resource"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, AG_NAME=$AG_NAME"
```

## Azure CLI solution (fully parameterized)
### 1) Create resource group and discover subscription scope
```bash
az group create --name "$RG_NAME" --location "$LOCATION"

SUB_ID="$(az account show --query id -o tsv)"
SUB_SCOPE="/subscriptions/${SUB_ID}"

echo "SUB_SCOPE=$SUB_SCOPE"
```

### 2) Create Action Group
```bash
AG_ID="$(az monitor action-group create \
  --resource-group "$RG_NAME" \
  --name "$AG_NAME" \
  --short-name "m05hlth" \
  --action email HealthOps "$ALERT_EMAIL" \
  --query id -o tsv)"

echo "AG_ID=$AG_ID"
```

### 3) Create Service Health and Resource Health alerts
```bash
SERVICE_ALERT_ID="$(az monitor activity-log alert create \
  --resource-group "$RG_NAME" \
  --name "$SERVICE_ALERT_NAME" \
  --scopes "$SUB_SCOPE" \
  --condition category=ServiceHealth \
  --action-group "$AG_ID" \
  --description "Notify on Azure Service Health events" \
  --query id -o tsv)"

RESOURCE_ALERT_ID="$(az monitor activity-log alert create \
  --resource-group "$RG_NAME" \
  --name "$RESOURCE_ALERT_NAME" \
  --scopes "$SUB_SCOPE" \
  --condition category=ResourceHealth \
  --action-group "$AG_ID" \
  --description "Notify on Azure Resource Health events" \
  --query id -o tsv)"

echo "SERVICE_ALERT_ID=$SERVICE_ALERT_ID"
echo "RESOURCE_ALERT_ID=$RESOURCE_ALERT_ID"
```

### 4) Validate alert definitions
```bash
az monitor activity-log alert list \
  --resource-group "$RG_NAME" \
  --query "[].{name:name,enabled:enabled,scopes:scopes}" -o table

az monitor action-group show \
  --resource-group "$RG_NAME" \
  --name "$AG_NAME" \
  --query "{name:name,emailReceivers:emailReceivers[].emailAddress}" -o jsonc
```

## ARM template solution (optional)
Use ARM/Bicep in enterprise environments to standardize health alert baselines across subscriptions.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- Activity Log alerts are control-plane event driven; notifications occur only when matching platform events happen.
- Reuse one Action Group for multiple health alerts to simplify operations.
