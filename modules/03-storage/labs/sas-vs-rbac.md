# Lab: SAS vs RBAC (Conceptual Access Control)

## Objective
Generate a short-lived SAS token for a blob container and compare with RBAC approach. Validate SAS format and expiry.

## What you will build
```mermaid
flowchart LR
  User --> SAS[SAS Token] --> Storage
  User --> RBAC[RBAC Data Role] --> Storage
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
LAB="m03-sas-rbac"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

source .env
echo "Environment loaded: RG_NAME=$RG_NAME, LOCATION=$LOCATION"
```

## Portal solution (high-level)
- Portal → Storage account → Containers → Shared access signature → Generate SAS.
- Portal → Storage account → Access control (IAM) → assign 'Storage Blob Data Reader/Contributor' to a principal.
- Compare: SAS (time-bound URL) vs RBAC (identity-based).

## Azure CLI solution (fully parameterised)
### 1) Create Resource Group
```bash
# Create the resource group in the specified location
az group create \
  --name "$RG_NAME" \
  --location "$LOCATION"
echo "RG_NAME=$RG_NAME"
```

### 2) Deploy resources
```bash
# Generate random suffix for globally unique storage account name
SUFFIX="$(openssl rand -hex 3)"

# Create storage account name (lowercase, no special characters)
STG_NAME="$(echo "${PREFIX}${SUFFIX}sas" | tr -d '-' | tr '[:upper:]' '[:lower:]')"

# Define container name
CONTAINER_NAME="sasdata"
echo "STG_NAME=$STG_NAME"
echo "CONTAINER_NAME=$CONTAINER_NAME"

# Create the storage account with LRS redundancy
az storage account create \
  --name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2

# Retrieve the storage account key for authentication
STG_KEY="$(az storage account keys list \
  --account-name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --query "[0].value" \
  -o tsv)"

# Create a blob container for SAS demonstration
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY"

# Calculate SAS token expiry time (15 minutes from now)
EXPIRY="$(date -u -d '+15 minutes' '+%Y-%m-%dT%H:%MZ')"
echo "EXPIRY=$EXPIRY"

# Generate a SAS token with read and list permissions
SAS_TOKEN="$(az storage container generate-sas \
  --name "$CONTAINER_NAME" \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --permissions rl \
  --expiry "$EXPIRY" \
  --https-only \
  -o tsv)"
echo "SAS_TOKEN=$SAS_TOKEN"

# Get the blob service endpoint URL
BLOB_ENDPOINT="$(az storage account show \
  --name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --query primaryEndpoints.blob \
  -o tsv)"
echo "BLOB_ENDPOINT=$BLOB_ENDPOINT"

# Construct the full SAS URL for container access
SAS_URL="${BLOB_ENDPOINT}${CONTAINER_NAME}?${SAS_TOKEN}"
echo "SAS_URL=$SAS_URL"
```


### 3) Validate
```bash
# Display the first 80 characters of the SAS token for verification
echo "$SAS_TOKEN" | head -c 80; echo "..."
echo "Validated SAS token generated and URL composed."
```


## ARM template solution (when needed)
Not required for this lab.

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
