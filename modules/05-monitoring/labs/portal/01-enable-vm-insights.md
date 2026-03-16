# Lab: Enable VM Insights + Query Logs (Minimal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a VM and a Log Analytics workspace, enable VM Insights/monitoring, and run a basic query. Capture workspace ID and VM ID.

## What you will build
```mermaid
flowchart LR
  VM --> Agent[Monitoring Agent] --> LAW[Log Analytics Workspace]
  LAW --> KQL[KQL Query] --> Results
```

## Estimated time
60–75 minutes

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
LAB="m05-vminsights"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

source .env
echo "Environment loaded: RG_NAME=$RG_NAME, LOCATION=$LOCATION"
```

## Portal solution (high-level)
- Portal → Create Log Analytics workspace.
- Portal → Create a small VM.
- Portal → VM → Insights → Enable.
- Portal → Logs (workspace) → run a Heartbeat query.



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