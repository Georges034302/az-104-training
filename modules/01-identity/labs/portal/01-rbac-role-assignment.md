# Lab: RBAC Role Assignment at Resource Group Scope
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a resource group, create a user (optional), and assign a built-in RBAC role at RG scope. Validate the assignment.

## What you will build

  [You]
   |
   v
 [Resource Group]
   |
   v
 [Role Assignment]
   |
   v
 [User/Group] ---> [Built-in Role]
   |
   v
 [ARM Access]

## Estimated time
20–30 minutes

## Cost + safety
- All resources are created in a **dedicated Resource Group** for this lab and can be deleted at the end.
- Default region: **australiaeast** (change if needed).

## Prerequisites
- Azure subscription with permission to create resources
- Azure CLI installed and authenticated (`az login`)
- (Optional) Azure Portal access

## Setup: Create environment file
```bash
# Create .env file with lab parameters
cat > .env << 'EOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m01-rbac"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

# Load environment variables
source .env
echo "Environment loaded: RG_NAME=$RG_NAME"
```


## Portal solution (step-by-step)
1. Sign in to the Azure Portal.
2. In the left menu, select **Resource groups** > **Create**.
  - Enter Resource Group Name: `${RG_NAME}` (from your .env file)
  - Select Region: `${LOCATION}`
  - Click **Review + Create** > **Create**.
3. In the new resource group, select **Access control (IAM)** from the left menu.
4. Click **Add** > **Add role assignment**.
  - Role: **Reader**
  - Assign access to: **User, group, or service principal**
  - Select: your user or another test user
  - Click **Next** > **Review + assign** > **Review + assign**.
5. To validate:
  - In **Access control (IAM)**, go to the **Role assignments** tab.
  - Filter by the assigned user and confirm the **Reader** role is listed at the resource group scope.



## Cleanup (required)
```bash
# Delete the resource group and all its resources asynchronously
az group delete \
  --name "$RG_NAME" \
  --yes \
  --no-wait
echo "Deleted RG: $RG_NAME (async)"
```

```bash
# Remove the .env file
rm -f .env
echo "Cleaned up .env file"
```

## Notes
- Every CLI command that returns an ID/URL is captured into a **variable** and echoed.
- If a command returns JSON, use `--query ... -o tsv` for clean variable assignment.