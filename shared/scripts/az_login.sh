#!/usr/bin/env bash
# Setup Azure CLI, Bicep, and helper tools, then authenticate.

set -e  # Exit on error

echo "=== Azure Environment Setup ==="

# 1. Install Azure CLI if not present
if ! command -v az &> /dev/null; then
    echo "Azure CLI not found. Installing..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    echo "✅ Azure CLI installed"
else
    echo "✅ Azure CLI already installed (version: $(az version --query '\"azure-cli\"' -o tsv))"
fi

# 2. Install Bicep CLI if not present
if ! az bicep version &> /dev/null; then
    echo "Bicep not found. Installing..."
    az bicep install
    echo "✅ Bicep installed"
else
    echo "✅ Bicep already installed (version: $(az bicep version))"
fi

# 3. Install jq (useful for JSON parsing in CLI workflows)
if ! command -v jq &> /dev/null; then
    echo "jq not found. Installing..."
    sudo apt-get update -qq && sudo apt-get install -y jq > /dev/null 2>&1
    echo "✅ jq installed"
else
    echo "✅ jq already installed (version: $(jq --version))"
fi

echo ""
echo "=== Azure Login ==="

# 4. Login to Azure (interactive)
az login

echo ""
echo "=== Active Subscription ==="
az account show --output table

echo ""
echo "✅ Setup complete! You're ready to run labs."
