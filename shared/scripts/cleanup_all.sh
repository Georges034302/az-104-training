#!/usr/bin/env bash
# WARNING: This script is intentionally conservative.
# It lists candidate AZ-104 lab resource groups (prefix match) but does not delete automatically.

PREFIX="${PREFIX:-az104}"
az group list --query "[?starts_with(name,'${PREFIX}-')].{name:name,location:location}" -o table
echo "Review the list and delete specific RGs manually with:"
echo "az group delete --name <rg-name> --yes --no-wait"
