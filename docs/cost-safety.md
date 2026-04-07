# Cost + Safety Guardrails

## Overview

These guardrails are designed to keep AZ-104 practice **safe, repeatable, and low cost**.

The repository assumes that every lab is short-lived and that cleanup is part of the lab—not an optional extra step.

---

## Core Safety Rules

- every lab uses a dedicated resource group for one-command cleanup
- cleanup is required at the end of each lab (`az group delete` + `rm -f .env`)
- `.env` files isolate local configuration between labs
- cleanup commands use `--no-wait` to start deletion immediately
- labs use the smallest practical SKUs needed for the learning objective

---

## Cost Optimization Defaults

### Region
- default location: `australiaeast`

### Compute
- preferred VM sizes: `Standard_B1s` or `Standard_B1ms`
- avoid larger families (for example D/F series) unless a lab explicitly requires them

### Storage
- prefer **Standard** performance tier for short-lived labs
- prefer **LRS** redundancy unless the lesson specifically needs another option
- use Hot/Cool tier changes only when required for lifecycle demonstrations

### Networking
- delete public IP resources as soon as validation is complete
- Module 02 load balancer labs intentionally use **Standard Load Balancer** and **Standard Public IP**
- avoid deploying extra services that are outside the lab guide

---

## Higher-Cost or Higher-Risk Services

Use these carefully and only when a lab explicitly requires them:

- VPN Gateway
- ExpressRoute
- Application Gateway
- Azure Site Recovery
- long-running VMs or restored backup artifacts left online after validation

---

## Before You Launch a Lab

- confirm you are in the correct Azure subscription
- read the cleanup section before creating resources
- use the provided `.env` pattern rather than hardcoding names
- keep the lab session short and focused
- avoid parallel lab runs unless you are tracking cleanup carefully

---

## Required Cleanup Pattern

```bash
# Delete Azure resources
az group delete --name "$RG_NAME" --yes --no-wait

# Delete local lab variables
rm -f .env
```

> **Important**: Azure resource deletion can continue in the background after the command returns. Recheck the portal or CLI later to confirm the resource group is fully gone.

---

## Monitor and Control Spend

### List remaining lab resource groups
```bash
az group list \
  --query "[?starts_with(name,'az104-')].{Name:name,Location:location}" \
  --output table
```

### Bulk-delete all AZ-104 lab groups
```bash
for rg in $(az group list --query "[?starts_with(name,'az104-')].name" -o tsv); do
  echo "Deleting $rg..."
  az group delete --name "$rg" --yes --no-wait
done
```

---

## Best Practices

- run labs only when you can verify cleanup right away
- set Azure budget or spending alerts on the subscription if possible
- check the Azure Portal for orphaned resources after each session
- keep secrets and local config in `.env`, not committed files
- delete restored disks, snapshots, or recovered resources after backup testing

---

## Cost Expectations

If resources are cleaned up within 1-2 hours, many labs stay inexpensive, but **actual cost is not guaranteed**.

Representative guidance only:
- per lab: often around **$0.10-$1.50 USD** for short runs
- full course: typically **low double-digit USD** if cleanup is prompt and services are not left running

Actual cost depends on:
- subscription type
- region pricing
- runtime duration
- backup retention and restore artifacts
- any orphaned resources left behind
