# Lab: Enable VM Insights and Query Logs (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough included only for the VM Insights onboarding step).

## Objective
Create a VM and Log Analytics workspace, onboard the VM to Azure Monitor Agent/VM Insights, and confirm log visibility with KQL.

## What you will build

 [Linux VM]
    |
    v
 [Azure Monitor Agent + VM Insights onboarding]
    |
    v
 [Log Analytics Workspace]
    |
    v
 [KQL Query Results]

## Estimated time
60-80 minutes

## Cost + safety
- Uses a small VM size for low lab cost.
- Resources are isolated in one resource group for full cleanup.
- Leave the lab running only as long as needed for data ingestion validation.

## Prerequisites
- Azure subscription with permission to create compute and monitoring resources
- Azure CLI installed and authenticated with `az login`
- Azure Portal access (required for reliable VM Insights onboarding flow)

## Setup: Create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m05vminsights"
RG_NAME="${PREFIX}-${LAB}-rg"
LAW_NAME="${PREFIX}-${LAB}-law"
VM_NAME="${PREFIX}-${LAB}-vm"
ADMIN_USER="azureuser"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, LAW_NAME=$LAW_NAME, VM_NAME=$VM_NAME"
```

## Azure CLI solution (fully parameterized)
### 1) Create resource group and workspace
```bash
az group create --name "$RG_NAME" --location "$LOCATION"

LAW_ID="$(az monitor log-analytics workspace create \
  --resource-group "$RG_NAME" \
  --workspace-name "$LAW_NAME" \
  --location "$LOCATION" \
  --query id -o tsv)"

LAW_WS_ID="$(az monitor log-analytics workspace show \
  --resource-group "$RG_NAME" \
  --workspace-name "$LAW_NAME" \
  --query customerId -o tsv)"

echo "LAW_ID=$LAW_ID"
echo "LAW_WORKSPACE_ID=$LAW_WS_ID"
```

### 2) Create VM and install Azure Monitor Agent extension
```bash
VM_ID="$(az vm create \
  --resource-group "$RG_NAME" \
  --name "$VM_NAME" \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username "$ADMIN_USER" \
  --generate-ssh-keys \
  --query id -o tsv)"

az vm extension set \
  --resource-group "$RG_NAME" \
  --vm-name "$VM_NAME" \
  --publisher Microsoft.Azure.Monitor \
  --name AzureMonitorLinuxAgent

echo "VM_ID=$VM_ID"
```

### 3) Onboard VM to VM Insights (Portal step for consistency)
```bash
echo "Portal step required: open VM > Insights > Enable."
echo "Select workspace $LAW_NAME and accept creation/association of Data Collection Rule if prompted."
```

Why this portal step is included: VM Insights onboarding UX and API wiring (DCR associations) changes over time; portal is the most stable AZ-104 practice path.

### 4) Validate monitoring pipeline
```bash
az vm extension show \
  --resource-group "$RG_NAME" \
  --vm-name "$VM_NAME" \
  --name AzureMonitorLinuxAgent \
  --query "{name:name,provisioningState:provisioningState}" -o table

# Query may return empty for first few minutes after onboarding.
az monitor log-analytics query \
  --workspace "$LAW_WS_ID" \
  --analytics-query "Heartbeat | where TimeGenerated > ago(30m) | where Computer contains '$VM_NAME' | summarize LastSeen=max(TimeGenerated) by Computer" \
  -o table
```

## ARM template solution (optional)
Use ARM/Bicep in production for repeatable VM + workspace deployment. Keep VM Insights onboarding verification in Portal for this training lab.

## Cleanup (required)
```bash
# Delete the resource group and all resources asynchronously
az group delete --name "$RG_NAME" --yes --no-wait
echo "Deleted RG: $RG_NAME (async)"

# Remove local lab files
rm -f .env
echo "Cleaned up local lab files"
```

## Notes
- First log ingestion can take several minutes after onboarding.
- If the query returns no rows initially, wait 5-10 minutes and query again.