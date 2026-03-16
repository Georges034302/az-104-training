# Lab: Storage Account + Blob Container (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Create a general-purpose v2 storage account, create a private blob container, upload a blob, list the container contents, and download the blob again to confirm end-to-end access.

## What you will build

 [Resource Group]
      |
      v
 [Storage Account]
      |
      v
 [Blob Container]
    /         \
   v           v
 [Upload]   [Download]

## Estimated time
30-40 minutes

## Cost + safety
- All resources are created in a dedicated resource group for easy cleanup.
- The lab uses Standard_LRS and a small sample file to keep cost low.
- The container is created without anonymous public access.

## Prerequisites
- Azure subscription with permission to create storage resources
- Azure CLI installed and authenticated with `az login`

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m03blob"
RG_NAME="${PREFIX}-${LAB}-rg"
CONTAINER_NAME="data"
LOCAL_FILE="hello-storage.txt"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, CONTAINER_NAME=$CONTAINER_NAME"
```

## Azure CLI solution (fully parameterized)
### 1) Create the resource group
```bash
az group create \
  --name "$RG_NAME" \
  --location "$LOCATION"
```

### 2) Create the storage account and container
```bash
SUFFIX="$(openssl rand -hex 3)"
STG_NAME="$(echo "${PREFIX}${LAB}${SUFFIX}" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-24)"

az storage account create \
  --name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2

STG_ID="$(az storage account show \
  --name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --query id -o tsv)"
STG_KEY="$(az storage account keys list \
  --account-name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --query "[0].value" -o tsv)"
BLOB_ENDPOINT="$(az storage account show \
  --name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --query primaryEndpoints.blob -o tsv)"

echo "STG_NAME=$STG_NAME"
echo "STG_ID=$STG_ID"
echo "BLOB_ENDPOINT=$BLOB_ENDPOINT"

az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --public-access off
```

### 3) Upload and download a sample blob
```bash
echo "Hello from AZ-104 Storage" > "$LOCAL_FILE"

az storage blob upload \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --container-name "$CONTAINER_NAME" \
  --name "$LOCAL_FILE" \
  --file "$LOCAL_FILE" \
  --overwrite true

az storage blob list \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --container-name "$CONTAINER_NAME" \
  --query "[].{name:name,tier:properties.accessTier}" \
  -o table

az storage blob download \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --container-name "$CONTAINER_NAME" \
  --name "$LOCAL_FILE" \
  --file "downloaded-$LOCAL_FILE" \
  --overwrite true
```

### 4) Validate
```bash
cmp "$LOCAL_FILE" "downloaded-$LOCAL_FILE"

az storage container show \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --name "$CONTAINER_NAME" \
  --query "{container:name,publicAccess:properties.publicAccess,lastModified:properties.lastModified}" \
  -o table
```

## ARM template solution (optional)
Use this if you want to deploy the storage account and container declaratively before running the upload/download commands.

```bash
cat > main.json << 'ARMEOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": { "type": "string" },
    "storageAccountName": { "type": "string" },
    "containerName": { "type": "string" },
    "skuName": { "type": "string", "defaultValue": "Standard_LRS" }
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2023-05-01",
      "name": "[parameters('storageAccountName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "[parameters('skuName')]"
      },
      "kind": "StorageV2",
      "properties": {
        "allowBlobPublicAccess": false,
        "minimumTlsVersion": "TLS1_2",
        "supportsHttpsTrafficOnly": true
      }
    },
    {
      "type": "Microsoft.Storage/storageAccounts/blobServices/containers",
      "apiVersion": "2023-05-01",
      "name": "[format('{0}/default/{1}', parameters('storageAccountName'), parameters('containerName'))]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName'))]"
      ],
      "properties": {
        "publicAccess": "None"
      }
    }
  ]
}
ARMEOF

az deployment group create \
  --resource-group "$RG_NAME" \
  --template-file main.json \
  --parameters \
    location="$LOCATION" \
    storageAccountName="$STG_NAME" \
    containerName="$CONTAINER_NAME"
```

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env main.json "$LOCAL_FILE" "downloaded-$LOCAL_FILE"
echo "Cleanup started: $RG_NAME"
```

## Notes
- The lab uses an account key for deterministic data-plane access. In production, prefer Microsoft Entra authorization when supported.
- Storage account names must be globally unique and lowercase only.