# Naming Standards

## Environment Variable Pattern

All labs use a `.env` file to store reusable variables.

```bash
# Common baseline used across modules
LOCATION="australiaeast"
PREFIX="az104"
LAB="m02-vnet"
RG_NAME="${PREFIX}-${LAB}-rg"
```

## Core Variables

- `LOCATION`: default Azure region (normally `australiaeast`)
- `PREFIX`: course prefix (normally `az104`)
- `LAB`: short lab identifier
- `RG_NAME`: resource group name derived from prefix and lab

## LAB Identifier Format

`LAB` values are short module-scoped slugs. Both hyphenated and compact forms are used in the repository:
- Hyphenated: `m01-rbac`, `m02-vnet`, `m05healthalerts`
- Compact: `m03blob`, `m03files`, `m04vmss`

Recommendation:
- Start with module number (`m01` ... `m05`)
- Follow with a short topic slug
- Keep names lowercase and script-friendly

## Globally Unique Resource Names

For globally-unique services (for example storage accounts and ACR), labs append a suffix.

```bash
# Preferred random suffix
SUFFIX="$(openssl rand -hex 3)"

# Optional fallback if openssl is unavailable
# SUFFIX="$(date +%s)"

STORAGE_ACCOUNT="${PREFIX}${LAB//-/}${SUFFIX}"
```

## Usage Pattern in Labs

```bash
# Create and load lab-local variables
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m03blob"
RG_NAME="${PREFIX}-${LAB}-rg"
ENVEOF

source .env

# Use variables consistently
az group create --name "$RG_NAME" --location "$LOCATION"
```

## Cleanup Pattern

Every lab cleans up cloud and local state:

```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
```

## Best Practices

- Use `.env` files in every lab
- Keep `PREFIX` and region consistent unless the lab requires otherwise
- Use suffixes for globally unique names
- Remove `.env` after each lab
- Add `.env` to `.gitignore`
