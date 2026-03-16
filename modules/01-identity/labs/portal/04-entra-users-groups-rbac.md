# Lab: Entra Users + Groups + RBAC (Group-Based Access)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a cloud user and security group in Entra ID, add the user to the group, and assign RBAC at resource group scope to the group.

## What you will build

 [Entra User]
   |
   v
 [Security Group]
   |
   v
 [Reader Role Assignment]
   |
   v
 [Resource Group Scope]

## Estimated time
30-45 minutes

## Cost + safety
- All resources are created in a dedicated Resource Group and can be deleted at the end.
- Default region: australiaeast (change if needed).

## Prerequisites
- Azure subscription with permission to create resources
- Azure Portal access
- Permission to create Entra users and groups in your tenant

## Setup: Create environment file
```bash
cat > .env << 'EOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m01-entra-group-rbac"
RG_NAME="${PREFIX}-${LAB}-rg"
EOF

source .env
echo "Environment loaded: RG_NAME=$RG_NAME, LOCATION=$LOCATION"
```

## Portal solution (step-by-step)
1. Sign in to the Azure Portal.
2. In the left menu, select **Resource groups** > **Create**.
  - Resource group name: `${RG_NAME}`
  - Region: `${LOCATION}`
  - Click **Review + Create** > **Create**.
3. In the left menu, select **Microsoft Entra ID** > **Users** > **New user**.
  - User name: e.g., `labuser####@yourdomain` (use your tenant domain)
  - Name: e.g., `Lab User ####`
  - Initial password: set and note for test
  - Click **Create**.
4. In **Microsoft Entra ID**, select **Groups** > **New group**.
  - Group type: **Security**
  - Group name: e.g., `az104-m01-rbac-group-####`
  - Membership type: **Assigned**
  - Click **Create**.
5. Open the new group > **Members** > **Add members**.
  - Select the user you just created
  - Click **Select** > **Save**.
6. In the left menu, select **Resource groups** > select `${RG_NAME}` > **Access control (IAM)** > **Add** > **Add role assignment**.
  - Role: **Reader**
  - Assign access to: **User, group, or service principal**
  - Select: the group you created
  - Click **Next** > **Review + assign** > **Review + assign**.
7. To validate:
  - In **Access control (IAM)**, go to **Role assignments** and filter by the group.
  - In **Microsoft Entra ID** > **Groups** > select your group > **Members** to confirm the user is present.

## Cleanup (required)
```bash
# Delete resource group and local env file
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started."
```

## Notes
- This lab demonstrates why group-based RBAC is preferred over direct user assignments.
- Role propagation and token refresh can take a few minutes in real environments.
