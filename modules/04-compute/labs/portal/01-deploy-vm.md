# Lab: Deploy a Linux VM (Simple)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a VNet, subnet, NSG, and deploy a small Linux VM. Capture public IP and validate SSH connectivity (optional).

## What you will build
```mermaid
flowchart LR
  Client --> SSH[SSH 22] --> PIP[Public IP] --> VM[Linux VM]
  VM --> NIC[NIC] --> Subnet --> VNet
  Subnet --> NSG[NSG Rule Allow SSH]
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
LAB="m04-vm"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

source .env
echo "Environment loaded: RG_NAME=$RG_NAME, LOCATION=$LOCATION"
```

## Portal solution (high-level)
- Portal → Virtual machines → Create.
- Choose Ubuntu LTS, size `B1s` if available.
- Create new VNet/subnet and NSG allowing SSH.
- Create public IP, set admin username + SSH key.
- Validate VM provisioning succeeded.



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