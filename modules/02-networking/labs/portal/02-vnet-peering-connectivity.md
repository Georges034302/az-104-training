# Lab: VNet Peering + Connectivity Check (Basic)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create two VNets, peer them in both directions, and validate peering state. (Optional VM test is kept minimal.)

## What you will build
```mermaid
flowchart LR
  VNetA[VNet A] <--> Peer[Peering] <--> VNetB[VNet B]
  Peer --> State[Connected]
```

## Estimated time
30–45 minutes

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
LAB="m02-peering"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

source .env
echo "Environment loaded: RG_NAME=$RG_NAME, LOCATION=$LOCATION"
```

## Portal solution (high-level)
- Portal → Create VNet A and VNet B with non-overlapping CIDRs.
- Open VNet A → Peerings → Add peering to VNet B.
- Open VNet B → Peerings → Add peering to VNet A.
- Validate both show **Connected**.



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