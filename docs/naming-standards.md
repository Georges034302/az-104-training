# Naming Standards

## Environment Variable Pattern

All labs use a `.env` file to store configuration variables:

```bash
# Example .env file structure
LOCATION="australiaeast"
PREFIX="az104"
LAB="m02-vnet"
RG="${PREFIX}-${LAB}-rg"
SUFFIX="$(openssl rand -hex 3)"
```

### Usage in Labs
```bash
# Create .env file
cat > .env << 'EOF'
LOCATION="australiaeast"
PREFIX="az104"
# ... other variables
EOF

# Source the variables
source .env

# Use in commands
az group create --name "$RG" --location "$LOCATION"
```

## Default Variables

- **LOCATION**: `"australiaeast"` (default region for all resources)
- **PREFIX**: `"az104"` (consistent prefix for all labs)
- **LAB**: `"<module>-<topic>"` (e.g., `m02-vnet`, `m03-storage`)
- **RG**: `"${PREFIX}-${LAB}-rg"` (resource group name pattern)

## Globally Unique Names

For resources requiring global uniqueness (storage accounts, ACR, etc.):

```bash
SUFFIX="$(openssl rand -hex 3)"  # 6-character random hex
STORAGE_ACCOUNT="${PREFIX}${LAB//-/}${SUFFIX}"  # Remove hyphens, add suffix
```

**Example**: `az104m03storage7a2f1b`

## Resource Tagging

Recommended tags for cost tracking and organization:

```bash
az group create \
  --name "$RG" \
  --location "$LOCATION" \
  --tags course=az104 module=02 lab=vnet
```

## Cleanup Pattern

Every lab includes cleanup of both Azure resources and local config:

```bash
# Delete resource group
az group delete --name "$RG" --yes --no-wait

# Delete .env file
rm -f .env
```

## Best Practices

✅ Use `.env` files for all lab variables  
✅ Add `.env` to `.gitignore` to prevent committing credentials  
✅ Use consistent PREFIX across all labs  
✅ Generate random SUFFIX for globally unique resources  
✅ Always clean up `.env` files after lab completion
