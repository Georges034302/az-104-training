# Lab: VM Scale Set Autoscale (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Deploy a VM Scale Set and configure autoscale rules based on CPU so the platform can scale out and in automatically.

## What you will build

 [CPU Metrics]
    |
    v
 [Autoscale Rules]
   /          \
  v            v
 [Scale Out] [Scale In]
     \      /
      v    v
     [VM Scale Set]

## Estimated time
45-60 minutes

## Cost + safety
- Autoscale can increase instance count. Keep max instance count low for labs.
- Use small VM size to limit cost.

## Prerequisites
- Azure subscription with rights to create VM Scale Sets and monitor settings
- Azure Portal access

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m04vmss"
RG_NAME="${PREFIX}-${LAB}-rg"
VMSS_NAME="${PREFIX}-${LAB}-vmss"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, VMSS_NAME=$VMSS_NAME"
```

## Portal solution (step-by-step)
### 1) Create resource group
1. Open Resource groups and select Create.
2. Set name ${RG_NAME} in region ${LOCATION}.
3. Create the resource group.

### 2) Create VM Scale Set
1. Open Virtual machine scale sets and select Create.
2. On Basics:
  - Resource group: ${RG_NAME}
  - Name: ${VMSS_NAME}
  - Region: ${LOCATION}
  - Orchestration mode: Uniform
  - Image: Ubuntu Server 22.04 LTS
  - Size: Standard_B1s (or closest available)
  - Initial instance count: 1
3. Complete networking defaults for lab scope and create the VMSS.

### 3) Configure autoscale
1. Open ${VMSS_NAME}.
2. Open Scaling (or Scale) in the left menu.
3. Select Custom autoscale.
4. Set:
  - Minimum instances: 1
  - Default instances: 1
  - Maximum instances: 3
5. Add scale-out rule:
  - Metric: Percentage CPU
  - Condition: Greater than 70
  - Duration/Aggregation: 5 minutes average
  - Action: Increase count by 1
6. Add scale-in rule:
  - Metric: Percentage CPU
  - Condition: Less than 30
  - Duration/Aggregation: 10 minutes average
  - Action: Decrease count by 1
7. Save autoscale settings.

### 4) Validate
1. In Scaling, confirm both rules are listed and autoscale is enabled.
2. In Instances, verify current instance count and VM state.
3. In Activity log, confirm autoscale setting updates were applied.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- Autoscale evaluation is periodic, so scaling is not immediate at threshold crossing.
- Use asymmetric thresholds to reduce repeated scale in/out oscillation.