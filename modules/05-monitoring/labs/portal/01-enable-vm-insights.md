# Lab: Enable VM Insights and Query Logs (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a VM and Log Analytics workspace, enable VM Insights onboarding, and verify telemetry with a KQL query.

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
- Use a small VM size to keep costs low.
- Stop and delete all lab resources at the end.
- First log ingestion can take several minutes.

## Prerequisites
- Azure subscription with rights to create compute and monitoring resources
- Azure Portal access

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m05vminsights"
RG_NAME="${PREFIX}-${LAB}-rg"
LAW_NAME="${PREFIX}-${LAB}-law"
VM_NAME="${PREFIX}-${LAB}-vm"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, LAW_NAME=$LAW_NAME, VM_NAME=$VM_NAME"
```

## Portal solution (step-by-step)
### 1) Create the resource group
1. Open Resource groups and select Create.
2. Set Resource group name to ${RG_NAME}.
3. Set Region to ${LOCATION}.
4. Select Review + create, then Create.

### 2) Create Log Analytics workspace
1. Open Log Analytics workspaces and select Create.
2. Set:
  - Resource group: ${RG_NAME}
  - Name: ${LAW_NAME}
  - Region: ${LOCATION}
3. Select Review + create, then Create.

### 3) Create VM
1. Open Virtual machines and select Create > Azure virtual machine.
2. In Basics, set:
  - Resource group: ${RG_NAME}
  - VM name: ${VM_NAME}
  - Region: ${LOCATION}
  - Image: Ubuntu Server 22.04 LTS
  - Size: B1s (or smallest available lab size)
  - Authentication type: SSH public key
3. Keep defaults for disk/network unless your subscription policy requires changes.
4. Select Review + create, then Create.

### 4) Enable VM Insights onboarding
1. Open the VM ${VM_NAME}.
2. In the left menu, select Insights.
3. Select Enable.
4. Choose existing workspace ${LAW_NAME}.
5. Accept creation/association prompts for data collection rule if shown.
6. Complete onboarding.

### 5) Validate telemetry with Logs
1. Open Log Analytics workspace ${LAW_NAME}.
2. Select Logs.
3. Run query:

```kusto
Heartbeat
| where TimeGenerated > ago(30m)
| where Computer contains "m05vminsights"
| summarize LastSeen=max(TimeGenerated) by Computer
```

4. Confirm at least one VM heartbeat row appears (allow 5-10 minutes after onboarding if empty initially).

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- Empty results immediately after onboarding are normal while data pipeline initializes.
- VM Insights depends on agent onboarding and workspace association, not just VM creation.