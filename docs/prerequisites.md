# Prerequisites

## Tools Required

All required tools are automatically installed by running:
```bash
./shared/scripts/az_login.sh
```

This script installs and configures:
- **Azure CLI** (latest version)
- **Bicep CLI** (for infrastructure as code)
- **jq** (for JSON parsing)
- Authenticates you with Azure
- Displays your active subscription

## Azure Requirements
- An Azure subscription with permissions to create resources
- Contributor or Owner role recommended for hands-on labs

## Optional Tools
- **VS Code** with Azure extensions for enhanced development experience
- **Git** for version control and tracking lab progress

## Lab Conventions

All labs follow consistent patterns:
- **Default Region**: `australiaeast`
- **Resource Naming**: `${PREFIX}-${LAB}-rg` (e.g., `az104-m02-vnet-rg`)
- **Environment Variables**: Stored in `.env` files per lab
- **Cleanup**: Each lab deletes its `.env` file and resource group

## Getting Started

1. Run the setup script once:
   ```bash
   ./shared/scripts/az_login.sh
   ```

2. Navigate to any lab and follow the instructions

3. Each lab creates its own `.env` file with required variables

4. Always run cleanup commands at the end of each lab
