# Lab: UDR Routing Simulation (Simple Route Table)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a route table, add a route, associate it to a subnet, and validate effective association. This lab keeps the next hop simple.

## What you will build
```mermaid
flowchart LR
  Subnet[Subnet] --> RT[Route Table]
  RT --> Route[Route: 0.0.0.0/0 -> Internet]
  Route --> NextHop[Next Hop]
```

## Estimated time
25–35 minutes

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
LAB="m02-udr"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

source .env
echo "Environment loaded: RG_NAME=$RG_NAME, LOCATION=$LOCATION"
```

## Portal solution (high-level)
- Portal → Create VNet + subnet.
- Portal → Route tables → Create.
- Add a route (e.g., `0.0.0.0/0` next hop Internet) for demo.
- Associate route table to subnet.



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