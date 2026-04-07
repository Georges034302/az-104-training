# Prerequisites

## Overview

This repository is designed for **hands-on AZ-104 practice** using both conceptual lessons and guided labs.

Current training scope:
- **5 modules**
- **27 lessons**
- **44 lab guides** (`22` CLI + ARM and `22` Portal)

The content assumes you have a valid Azure subscription and permission to create and delete short-lived lab resources safely.

---

## Required Tools

Run the shared setup script once per environment:

```bash
./shared/scripts/az_login.sh
```

This script installs or verifies:
- Azure CLI
- Bicep CLI
- `jq`
- Azure sign-in session
- active subscription context

---

## Azure Access and Permissions

### Baseline permissions for most labs
- Azure subscription access with rights to create resource groups and resources
- `Contributor` role (or `Owner`) on the target subscription or resource group

### Additional permissions for identity and governance labs
- permission in **Microsoft Entra ID** to create users and groups
- permission to assign RBAC at resource group scope or higher

### Additional permissions for monitoring labs
- ability to create Azure Monitor alerts, Action Groups, Log Analytics workspaces, and Recovery Services vaults
- permission to create Activity Log alerts at subscription scope where required

---

## Recommended Local Environment

- Bash shell or compatible terminal
- VS Code for opening the repository and following the markdown guides
- SSH key support for Linux VM labs that use `--generate-ssh-keys`
- Git (optional, but useful for tracking progress)

---

## Lab Conventions Used Throughout the Repo

All labs follow consistent conventions so that instructions stay reusable and precise:

- default region: `australiaeast`
- environment variables stored in per-lab `.env` files
- resource group naming based on `${PREFIX}-${LAB}-rg`
- explicit validation steps after deployment
- required cleanup of both Azure resources and local `.env`

---

## Timing Expectations

Some Azure operations are asynchronous and may not produce immediate results.

Examples:
- Log Analytics ingestion may take several minutes.
- VM Insights and monitoring signals may not appear immediately.
- Backup jobs and recovery points may require waiting before validation.

Do not assume a configuration failed until you have allowed reasonable time for the service to finish provisioning or ingesting data.

---

## Recommended Start Sequence

1. Run the setup script:
   ```bash
   ./shared/scripts/az_login.sh
   ```
2. Review [`docs/cost-safety.md`](cost-safety.md) before creating resources.
3. Open the target module `README.md` to understand the learning outcomes.
4. Read the lesson first, then perform the matching lab in either `labs/cli-arm/` or `labs/portal/`.
5. Complete the validation checks and then clean up immediately.

---

## Before You Begin Checklist

- [ ] Azure CLI is installed and authenticated
- [ ] Correct subscription is selected
- [ ] You understand the objective and cleanup steps
- [ ] You are using the intended lab track (`CLI + ARM` or `Portal`)
- [ ] You are ready to delete the resource group when the lab is finished
