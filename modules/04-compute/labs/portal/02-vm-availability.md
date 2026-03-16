# Lab: VM Availability (Availability Set OR Zone)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Deploy two VMs into an availability set (simple) and understand how fault/update domains apply. Zone deployment is mentioned as an alternative.

## What you will build
```mermaid
flowchart LR
  AS[Availability Set] --> FD[Fault Domains]
  AS --> UD[Update Domains]
  FD --> VM1[VM1]
  FD --> VM2[VM2]
```

## Estimated time
45–60 minutes

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
LAB="m04-availability"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

source .env
echo "Environment loaded: RG_NAME=$RG_NAME, LOCATION=$LOCATION"
```

## Portal solution (high-level)
- Portal → Create an Availability Set (choose fault/update domain count).
- Create VM1 and VM2 and select the same Availability Set.
- Validate under Availability Set → VMs.
- Alternative: create VMs in different Availability Zones (if region/sku supports).



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