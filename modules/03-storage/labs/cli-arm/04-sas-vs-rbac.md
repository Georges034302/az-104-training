# Lab: SAS vs RBAC for Blob Access (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Create a storage account and blob container, upload a sample blob, generate a short-lived SAS token for the container, and assign an Azure RBAC data role at storage account scope for comparison.

## What you will build

 [Storage Account]
    /        \
   v          v
 [SAS Token] [RBAC Data Role]
      \      /
       v    v
   [Blob Container]

## Estimated time
35-45 minutes

## Cost + safety
- The lab uses a single storage account and one small blob.
- SAS tokens are intentionally short-lived.
- RBAC propagation can take several minutes, so validation focuses on the assignment object and scope.

## Prerequisites
- Azure subscription with permission to create storage resources and assign Azure roles
- Azure CLI installed and authenticated with `az login`
- If automatic signed-in user detection does not work in your tenant, have the Microsoft Entra object ID of the target principal available

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m03sasrbac"
RG_NAME="${PREFIX}-${LAB}-rg"
CONTAINER_NAME="sasdata"
LOCAL_FILE="rbac-sas-sample.txt"
ROLE_NAME="Storage Blob Data Reader"
ASSIGNEE_OBJECT_ID=""
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, CONTAINER_NAME=$CONTAINER_NAME, ROLE_NAME=$ROLE_NAME"
```

## Azure CLI solution (fully parameterized)
### 1) Create the resource group
```bash
az group create \
  --name "$RG_NAME" \
  --location "$LOCATION"
```

### 2) Create the storage account, container, and sample blob
```bash
SUFFIX="$(openssl rand -hex 3)"
STG_NAME="$(echo "${PREFIX}${LAB}${SUFFIX}" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-24)"

az storage account create \
  --name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access false

STG_KEY="$(az storage account keys list \
  --account-name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --query "[0].value" -o tsv)"
BLOB_ENDPOINT="$(az storage account show \
  --name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --query primaryEndpoints.blob -o tsv)"

az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --public-access off

echo "SAS and RBAC comparison blob" > "$LOCAL_FILE"

az storage blob upload \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --container-name "$CONTAINER_NAME" \
  --name "$LOCAL_FILE" \
  --file "$LOCAL_FILE" \
  --overwrite true

echo "STG_NAME=$STG_NAME"
echo "BLOB_ENDPOINT=$BLOB_ENDPOINT"
```

### 3) Generate a short-lived SAS token
```bash
EXPIRY_UTC="$(date -u -d '+30 minutes' '+%Y-%m-%dT%H:%MZ')"

SAS_TOKEN="$(az storage container generate-sas \
  --name "$CONTAINER_NAME" \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --permissions rl \
  --expiry "$EXPIRY_UTC" \
  --https-only \
  -o tsv)"

SAS_URL="${BLOB_ENDPOINT}${CONTAINER_NAME}?${SAS_TOKEN}"

echo "EXPIRY_UTC=$EXPIRY_UTC"
echo "SAS_URL=$SAS_URL"
```

### 4) Assign an RBAC data role at storage account scope
```bash
if [ -z "$ASSIGNEE_OBJECT_ID" ]; then
  ASSIGNEE_OBJECT_ID="$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)"
fi

if [ -z "$ASSIGNEE_OBJECT_ID" ]; then
  echo "Set ASSIGNEE_OBJECT_ID in .env to the Microsoft Entra object ID of the principal that should receive the RBAC role." >&2
  exit 1
fi

SUB_ID="$(az account show --query id -o tsv)"
STG_SCOPE="/subscriptions/${SUB_ID}/resourceGroups/${RG_NAME}/providers/Microsoft.Storage/storageAccounts/${STG_NAME}"

az role assignment create \
  --assignee-object-id "$ASSIGNEE_OBJECT_ID" \
  --role "$ROLE_NAME" \
  --scope "$STG_SCOPE"
```

### 5) Validate
```bash
echo "$SAS_TOKEN" | head -c 80
echo

az role assignment list \
  --assignee-object-id "$ASSIGNEE_OBJECT_ID" \
  --scope "$STG_SCOPE" \
  --query "[].{role:roleDefinitionName,scope:scope,principalId:principalId}" \
  -o table
```

## ARM template solution (when needed)
Not required for this lab. SAS generation and RBAC role assignment are operational actions that depend on runtime credentials and target identity, so they are intentionally performed with Azure CLI.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env "$LOCAL_FILE"
echo "Cleanup started: $RG_NAME"
```

## Notes
- A SAS token is a delegated secret; treat it like a credential and do not leave it in shell history longer than necessary.
- RBAC authorization can take time to propagate. If you test data access immediately after assignment, allow a few minutes before concluding the role failed.