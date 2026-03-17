# Cost + Safety Guardrails

## Core Safety Rules

- Every lab uses a dedicated resource group for one-command cleanup
- Cleanup is required at the end of each lab (`az group delete` + `rm -f .env`)
- `.env` files isolate local configuration between labs
- Cleanup commands use `--no-wait` to start deletion immediately
- Labs use the smallest practical SKUs for learning outcomes

## Cost Optimization Defaults

### Region
- Default location: `australiaeast`

### Compute
- Preferred VM sizes: `Standard_B1s` or `Standard_B1ms`
- Avoid larger families (for example D/F series) unless a lab explicitly needs them

### Storage
- Prefer Standard performance tier
- Prefer LRS redundancy for short-lived labs
- Use Hot/Cool tiers only as needed for lifecycle demonstrations

### Networking
- Public IP resources should be deleted immediately after validation
- Module 02 load balancer labs use Standard Load Balancer and Standard Public IP by design
- Avoid deploying additional networking services not required by the guide

## Higher-Cost Services (Use Carefully)

- VPN Gateway: not part of the standard lab set
- ExpressRoute: not part of the standard lab set
- Application Gateway: do not deploy unless explicitly required by a lab
- Azure Site Recovery: keep tests lightweight and short-lived

## Lab Cleanup Checklist

```bash
# Delete Azure resources
az group delete --name "$RG_NAME" --yes --no-wait

# Delete local lab variables
rm -f .env
```

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

## Best Practices

- Run labs when you can verify cleanup right away
- Set Azure budget/spending alerts on the subscription
- Check the Azure Portal for orphaned resources after each session
- Keep secrets and local config in `.env`, not committed files

## Estimated Costs

If resources are cleaned up within 1-2 hours:
- Per lab: about $0.10-$1.50 USD
- Full course: typically low double-digit USD, depending on runtime and region

Actual cost depends on subscription type, region pricing, and how long resources are left running.
