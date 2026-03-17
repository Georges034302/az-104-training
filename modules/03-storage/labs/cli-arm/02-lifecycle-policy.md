# Lab: Blob Lifecycle Management Policy (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Create a storage account, add a blob container and sample block blob, then apply a lifecycle management policy that moves base blobs to the Cool tier after seven days. Validate the policy configuration rather than waiting for an actual tier transition.

## What you will build

 [Storage Account]
      |
      v
 [Blob Container]
      |
      v
 [Lifecycle Policy]
      |
      v
 [Move Base Blobs To Cool After 7 Days]

## Estimated time
30-40 minutes

## Cost + safety
- The lab uses a small storage account and a small sample blob.
- Lifecycle processing is asynchronous, so this lab validates policy configuration only.
- The resource group can be deleted when finished.

## Prerequisites
- Azure subscription with permission to create storage resources
- Azure CLI installed and authenticated with `az login`

## Setup: Create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m03life"
RG_NAME="${PREFIX}-${LAB}-rg"
CONTAINER_NAME="data"
BLOB_NAME="sample-lifecycle.txt"
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

### 2) Create the storage account and sample blob
```bash
SUFFIX="$(openssl rand -hex 3)"
STG_NAME="$(echo "${PREFIX}${LAB}${SUFFIX}" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-24)"

az storage account create \
  --name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2

STG_KEY="$(az storage account keys list \
  --account-name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --query "[0].value" -o tsv)"

az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --public-access off

echo "Lifecycle test blob" > "$BLOB_NAME"

az storage blob upload \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --container-name "$CONTAINER_NAME" \
  --name "$BLOB_NAME" \
  --file "$BLOB_NAME" \
  --overwrite true

echo "STG_NAME=$STG_NAME"
```

### 3) Create and apply the lifecycle policy
```bash
cat > policy.json << 'POLICYEOF'
{
  "rules": [
    {
      "enabled": true,
      "name": "move-block-blobs-to-cool",
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": [
            "blockBlob"
          ]
        },
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 7
            }
          }
        }
      }
    }
  ]
}
POLICYEOF

az storage account management-policy create \
  --account-name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --policy @policy.json

POLICY_ID="$(az storage account management-policy show \
  --account-name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --query id -o tsv)"

echo "POLICY_ID=$POLICY_ID"
```

### 4) Validate
```bash
az storage account management-policy show \
  --account-name "$STG_NAME" \
  --resource-group "$RG_NAME" \
  --query "policy.rules[].{name:name,enabled:enabled,moveToCool:definition.actions.baseBlob.tierToCool.daysAfterModificationGreaterThan}" \
  -o table

az storage blob show \
  --account-name "$STG_NAME" \
  --account-key "$STG_KEY" \
  --container-name "$CONTAINER_NAME" \
  --name "$BLOB_NAME" \
  --query "{blob:name,currentTier:properties.accessTier,lastModified:properties.lastModified}" \
  -o table
```

## ARM template solution (optional)
Use this if you want to deploy the storage account and management policy declaratively.

```bash
cat > main.json << 'ARMEOF'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": { "type": "string" },
    "storageAccountName": { "type": "string" }
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
      "type": "Microsoft.Storage/storageAccounts/managementPolicies",
      "apiVersion": "2023-05-01",
      "name": "[format('{0}/default', parameters('storageAccountName'))]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName'))]"
      ],
      "properties": {
        "policy": {
          "rules": [
            {
              "enabled": true,
              "name": "move-block-blobs-to-cool",
              "type": "Lifecycle",
              "definition": {
                "filters": {
                  "blobTypes": [
                    "blockBlob"
                  ]
                },
                "actions": {
                  "baseBlob": {
                    "tierToCool": {
                      "daysAfterModificationGreaterThan": 7
                    }
                  }
                }
              }
            }
          ]
        }
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
    storageAccountName="$STG_NAME"
```

## Cleanup (required)
```bash
# Delete the resource group and all resources asynchronously
az group delete --name "$RG_NAME" --yes --no-wait
echo "Deleted RG: $RG_NAME (async)"

# Remove local lab files
rm -f .env main.json policy.json "$BLOB_NAME"
echo "Cleaned up local lab files"
```

## Notes
- The policy does not force an immediate move during the lab. Azure evaluates lifecycle rules asynchronously.
- Lifecycle policies are account-level constructs; the same policy can apply to multiple containers when filters match.