# Lab: Basic Azure Load Balancer (Conceptual + Minimal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a public IP and a basic Load Balancer frontend + health probe. Backend pool is created; attaching VMs is optional to keep cost low.

## What you will build
```mermaid
flowchart LR
  Client --> PIP[Public IP] --> LB[Load Balancer]
  LB --> Probe[Health Probe]
  LB --> Pool[Backend Pool]
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
LAB="m02-lb"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

source .env
echo "Environment loaded: RG_NAME=$RG_NAME, LOCATION=$LOCATION"
```

## Portal solution (high-level)
- Portal → Public IP addresses → Create.
- Portal → Load balancers → Create (Public).
- Add frontend IP configuration using the Public IP.
- Add health probe (TCP 80).
- Add backend pool (VMs optional).



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