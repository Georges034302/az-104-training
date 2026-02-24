# Cost + Safety Guardrails

## Core Safety Rules

✅ **Dedicated Resource Groups**: Every lab creates its own resource group for easy cleanup  
✅ **Cleanup Required**: Always run cleanup commands at the end of each lab  
✅ **Environment Isolation**: Use `.env` files to prevent configuration conflicts  
✅ **Async Deletion**: All cleanup uses `--no-wait` flag for faster completion  
✅ **Low-Cost SKUs**: All labs use the smallest viable SKU sizes

## Cost Optimization Settings

### Default Region
- **Location**: `australiaeast` (consistent across all labs)

### VM Sizes
- **Preferred**: `Standard_B1s` or `Standard_B1ms` (burstable, cost-effective)
- **Avoid**: D-series, F-series unless specifically required for testing

### Storage
- **Tier**: Standard (not Premium) unless testing performance
- **Redundancy**: LRS (locally redundant) for lab purposes
- **Access Tier**: Hot for short-lived blobs, Cool for testing lifecycle policies

### Networking
- **Public IPs**: Delete after use, avoid Standard SKU unless needed
- **Load Balancers**: Use Basic SKU for labs
- **VPN Gateway**: Not used (high cost)
- **Application Gateway**: Basic SKU or omitted

## High-Cost Services to Avoid

🚫 **VPN Gateway** ($30-300+/month) - Not included in labs  
🚫 **ExpressRoute** ($50+/month) - Not included  
⚠️ **Application Gateway** ($125+/month) - Use Basic tier only  
⚠️ **Azure Site Recovery** - Keep labs lightweight and short-lived  
⚠️ **Standard Public IPs** - Use Basic tier for labs

## Lab Cleanup Checklist

Every lab includes this cleanup pattern:

```bash
# 1. Delete Azure resource group (async)
az group delete --name "$RG" --yes --no-wait

# 2. Delete local .env file
rm -f .env
```

## Monitoring Your Costs

### Check All Lab Resource Groups
```bash
az group list \
  --query "[?starts_with(name,'az104-')].{Name:name,Location:location}" \
  --output table
```

### Delete All Lab Resource Groups
```bash
for rg in $(az group list --query "[?starts_with(name,'az104-')].name" -o tsv); do
  echo "Deleting $rg..."
  az group delete --name "$rg" --yes --no-wait
done
```

## Best Practices

💡 **Run labs during business hours** - Easier to remember cleanup  
💡 **Set Azure spending alerts** - Get notified of unexpected costs  
💡 **Review Azure Portal regularly** - Check for orphaned resources  
💡 **Use `.env` files** - Prevents leaving hardcoded credentials  
💡 **Test cleanup commands** - Verify resource deletion completed

## Estimated Lab Costs

If cleaned up within 1-2 hours per lab:
- **Per Lab**: $0.10 - $1.00 USD
- **Full Course**: ~$10 - $20 USD total

**Note**: Costs may vary by region and subscription type. Always verify deletion in Azure Portal.
