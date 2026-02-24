# Prerequisites

## Tools
- Azure CLI (latest)
- An Azure subscription where you can create resources
- Optional: VS Code + Azure extensions

## Login
```bash
# az login
# az account show
```

## Conventions
- All labs default to `LOCATION=australiaeast`
- Each lab creates a dedicated Resource Group named from:
  - `PREFIX` + `LAB` → `${PREFIX}-${LAB}-rg`
