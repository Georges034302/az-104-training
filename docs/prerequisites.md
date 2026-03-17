# Prerequisites

## Course Scope

Current training content in this repository:
- 5 modules
- 27 lessons
- 44 lab guides (22 CLI + ARM and 22 Portal)

## Tools Required

Run the setup script once per environment:

```bash
./shared/scripts/az_login.sh
```

This script installs/configures:
- Azure CLI
- Bicep CLI
- jq
- Azure authentication session
- Active subscription check

## Azure Permissions Required

Baseline permissions for most labs:
- Azure subscription access with rights to create resource groups and resources
- Contributor role (or Owner) on the target subscription/resource group

Additional permissions for identity-focused labs:
- Permission in Microsoft Entra ID to create users and groups
- Permission to assign RBAC at resource group scope

## Optional Tools

- VS Code with Azure extensions
- Git for version control and progress tracking

## Lab Conventions

All labs follow consistent patterns:
- Default region: `australiaeast`
- Environment variables stored in per-lab `.env` files
- Resource group naming based on `${PREFIX}-${LAB}-rg`
- Required cleanup of both Azure resources and local `.env`

## Getting Started

1. Run setup:
   ```bash
   ./shared/scripts/az_login.sh
   ```
2. Open a lab in either track: `labs/cli-arm/` or `labs/portal/`
3. Create and source the lab `.env` file as instructed
4. Complete validation steps, then run cleanup
