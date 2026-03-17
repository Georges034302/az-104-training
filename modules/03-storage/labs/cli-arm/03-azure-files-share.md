# Lab: Azure Files Share (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Create a storage account and SMB-based Azure file share, upload a test file, confirm quota settings, and validate the share endpoint. Mounting the share is optional and not required for this lab.

## What you will build

 [Resource Group]
      |
      v
 [Storage Account]
      |
      v
 [Azure File Share]
    /         \
   v           v
 [Quota]    [Uploaded File]

## Estimated time
30-40 minutes

## Cost + safety
- The lab uses a small standard file share with a low quota.
- No VM is required, which keeps cost down.
- Mounting over SMB may be blocked in some corporate or ISP networks because of outbound port 445 restrictions.

## Prerequisites
- Azure subscription with permission to create storage resources
- Azure CLI installed and authenticated with `az login`

## Setup: Create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m03files"
RG_NAME="${PREFIX}-${LAB}-rg"
SHARE_NAME="share1"
QUOTA_GB="5"
LOCAL_FILE="share-test.txt"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, SHARE_NAME=$SHARE_NAME"
```

## Azure CLI solution (fully parameterized)
### 1) Create the resource group
```bash
az group create \
  --name "$RG_NAME" \
  --location "$LOCATION"
```

### 2) Create the storage account and file share
```bash
SUFFIX="$(openssl rand -hex 3)"
STG_NAME="$(echo "${PREFIX}${LAB}${SUFFIX}" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-24)"

az storage account create \
  --name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --enable-large-file-share false

FILE_ENDPOINT="$(az storage account show \
  --name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --query primaryEndpoints.file -o tsv)"
STG_KEY="$(az storage account keys list \
  --account-name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --query "[0].value" -o tsv)"

echo "STG_NAME=$STG_NAME"
echo "FILE_ENDPOINT=$FILE_ENDPOINT"

az storage share-rm create \
  --resource-group "$RG_NAME" \
  --storage-account "$STG_NAME" \
  --name "$SHARE_NAME" \
  --quota "$QUOTA_GB"
```

### 3) Upload a sample file
```bash
echo "Azure Files lab content" > "$LOCAL_FILE"

az storage file upload \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --share-name "$SHARE_NAME" \
  --source "$LOCAL_FILE" \
  --path "$LOCAL_FILE"

az storage file list \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --share-name "$SHARE_NAME" \
  -o table
```

### 4) Validate
```bash
az storage share-rm show \
  --resource-group "$RG_NAME" \
  --storage-account "$STG_NAME" \
  --name "$SHARE_NAME" \
  --query "{share:name,quota:shareQuota,enabledProtocol:enabledProtocols}" \
  -o table

az storage file show \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --share-name "$SHARE_NAME" \
  --path "$LOCAL_FILE" \
  --query "{name:name,contentLength:properties.contentLength,lastModified:properties.lastModified}" \
  -o table
```

## ARM template solution (optional)
Use this if you want to create the storage account and share declaratively before running the upload steps.

```bash
cat > main.json << 'ARMEOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": { "type": "string" },
    "storageAccountName": { "type": "string" },
    "shareName": { "type": "string" },
    "shareQuota": { "type": "int", "defaultValue": 5 }
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2023-05-01",
      "name": "[parameters('storageAccountName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "Standard_LRS"
      },
      "kind": "StorageV2",
      "properties": {
        "minimumTlsVersion": "TLS1_2",
        "supportsHttpsTrafficOnly": true
      }
    },
    {
      "type": "Microsoft.Storage/storageAccounts/fileServices/shares",
      "apiVersion": "2023-05-01",
      "name": "[format('{0}/default/{1}', parameters('storageAccountName'), parameters('shareName'))]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName'))]"
      ],
      "properties": {
        "shareQuota": "[parameters('shareQuota')]"
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
    shareName="$SHARE_NAME" \
    shareQuota="$QUOTA_GB"
```

## Cleanup (required)
```bash
# Delete the resource group and all resources asynchronously
az group delete --name "$RG_NAME" --yes --no-wait
echo "Deleted RG: $RG_NAME (async)"

# Remove local lab files
rm -f .env main.json "$LOCAL_FILE"
echo "Cleaned up local lab files"
```

## Notes
- This lab validates Azure Files objects and data-plane upload, not SMB mounting.
- If you later mount the share from a client, confirm network policy allows outbound TCP 445.