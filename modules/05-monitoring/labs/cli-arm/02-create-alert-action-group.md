# Lab: Create CPU Alert and Action Group (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Create a VM, build an email-based Action Group, configure a CPU metric alert, and verify alert rule scope and action wiring.

## What you will build

 [VM: Percentage CPU Metric]
            |
            v
      [Metric Alert Rule]
            |
            v
        [Action Group]
            |
            v
     [Email Notification]

## Estimated time
40-55 minutes

## Cost + safety
- Uses one small VM for metric signal generation.
- Resources are grouped for one-command cleanup.
- Email notifications may be sent if the alert triggers.

## Prerequisites
- Azure subscription with rights to create VM and monitor resources
- Azure CLI installed and authenticated with `az login`
- A valid email inbox for Action Group receiver testing

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m05alerts"
RG_NAME="${PREFIX}-${LAB}-rg"
VM_NAME="${PREFIX}-${LAB}-vm"
AG_NAME="${PREFIX}-${LAB}-ag"
ALERT_NAME="${PREFIX}-${LAB}-cpu-high"
ADMIN_USER="azureuser"
ALERT_EMAIL="you@example.com"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, VM_NAME=$VM_NAME, AG_NAME=$AG_NAME"
```

## Azure CLI solution (fully parameterized)
### 1) Create target VM
```bash
az group create --name "$RG_NAME" --location "$LOCATION"

VM_ID="$(az vm create \
  --resource-group "$RG_NAME" \
  --name "$VM_NAME" \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username "$ADMIN_USER" \
  --generate-ssh-keys \
  --query id -o tsv)"

echo "VM_ID=$VM_ID"
```

### 2) Create Action Group
```bash
AG_ID="$(az monitor action-group create \
  --resource-group "$RG_NAME" \
  --name "$AG_NAME" \
  --short-name "m05ag" \
  --action email OpsTeam "$ALERT_EMAIL" \
  --query id -o tsv)"

echo "AG_ID=$AG_ID"
```

### 3) Create CPU metric alert rule
```bash
ALERT_ID="$(az monitor metrics alert create \
  --resource-group "$RG_NAME" \
  --name "$ALERT_NAME" \
  --scopes "$VM_ID" \
  --description "Trigger when average CPU exceeds 70 percent over 5 minutes" \
  --condition "avg Percentage CPU > 70" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --action "$AG_ID" \
  --query id -o tsv)"

echo "ALERT_ID=$ALERT_ID"
```

### 4) Validate configuration
```bash
az monitor action-group show \
  --resource-group "$RG_NAME" \
  --name "$AG_NAME" \
  --query "{name:name,enabled:enabled,emailReceivers:emailReceivers[].name}" -o jsonc

az monitor metrics alert show \
  --resource-group "$RG_NAME" \
  --name "$ALERT_NAME" \
  --query "{name:name,severity:severity,enabled:enabled,scopes:scopes,actions:actions}" -o jsonc
```

### 5) Optional trigger simulation
```bash
echo "Optional: generate CPU load in VM to test end-to-end notification path."
echo "If you skip this, control-plane validation above is still valid for AZ-104 lab scope."
```

## ARM template solution (optional)
Use ARM/Bicep for organization-wide alert baselines. This lab focuses on admin operations through Azure CLI.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- Keep alert thresholds realistic for your workload baseline to reduce noise.
- Action Group resources are reusable across multiple alert rules.