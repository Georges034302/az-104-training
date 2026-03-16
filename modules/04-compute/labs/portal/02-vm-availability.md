# Lab: VM Availability with Availability Set (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Deploy two VMs in one availability set and verify they are placed under the same availability-set construct for fault and update domain distribution.

## What you will build

 [Availability Set]
      |
      +--> [VM1]
      +--> [VM2]
      +--> [Fault Domains]
      +--> [Update Domains]

## Estimated time
45-60 minutes

## Cost + safety
- This lab uses two VMs. Use small sizes and clean up quickly.
- Keep this lab focused on availability-set behavior, not zone deployment.

## Prerequisites
- Azure subscription with rights to create compute resources
- Azure Portal access

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m04avail"
RG_NAME="${PREFIX}-${LAB}-rg"
AS_NAME="${PREFIX}-${LAB}-as"
VM1_NAME="${PREFIX}-${LAB}-vm1"
VM2_NAME="${PREFIX}-${LAB}-vm2"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, AS_NAME=$AS_NAME"
```

## Portal solution (step-by-step)
### 1) Create resource group
1. Open Resource groups and select Create.
2. Set name ${RG_NAME} and region ${LOCATION}.
3. Select Review + create, then Create.

### 2) Create availability set
1. Open Availability sets and select Create.
2. Set:
   - Resource group: ${RG_NAME}
   - Name: ${AS_NAME}
   - Region: ${LOCATION}
   - Fault domains: 2
   - Update domains: 5
3. Select Review + create, then Create.

### 3) Create VM1 in the availability set
1. Open Virtual machines and select Create.
2. On Basics:
   - Resource group: ${RG_NAME}
   - Name: ${VM1_NAME}
   - Region: ${LOCATION}
   - Availability options: Availability set
   - Availability set: ${AS_NAME}
   - Image: Ubuntu Server 22.04 LTS
   - Size: Standard_B1s (or closest available)
3. Complete the wizard and create VM1.

### 4) Create VM2 in the same availability set
1. Repeat VM creation.
2. Set VM name to ${VM2_NAME}.
3. Set Availability options to Availability set and select ${AS_NAME}.
4. Create VM2.

### 5) Validate
1. Open Availability sets > ${AS_NAME}.
2. Confirm both ${VM1_NAME} and ${VM2_NAME} appear under Virtual machines.
3. Confirm fault and update domain configuration is visible on the availability set resource.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- A VM cannot be both zonal and in an availability set at the same time.
- If your design requires datacenter-level fault isolation, use availability zones instead of availability sets.