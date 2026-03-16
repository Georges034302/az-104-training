# Lab: Entra Users + Groups + RBAC (Group-Based Access)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

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
- Azure CLI installed and authenticated (az login)
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

## Azure CLI solution (fully parameterised)
### 1) Create Resource Group
```bash
# Create the resource group in the specified location
az group create \
  --name "$RG_NAME" \
  --location "$LOCATION"
echo "RG_NAME=$RG_NAME"
```

### 2) Deploy resources
```bash
# Get signed-in UPN and derive tenant domain for test user creation
SIGNED_IN_UPN="$(az account show --query user.name -o tsv)"
UPN_DOMAIN="${SIGNED_IN_UPN#*@}"
echo "UPN_DOMAIN=$UPN_DOMAIN"

# Create unique user and group names
SUFFIX="$(date +%s)"
LAB_USER_UPN="labuser${SUFFIX}@${UPN_DOMAIN}"
LAB_USER_DISPLAY="Lab User ${SUFFIX}"
GROUP_NAME="az104-m01-rbac-group-${SUFFIX}"
TEMP_PASSWORD='TempP@ssw0rd!123'
echo "LAB_USER_UPN=$LAB_USER_UPN"
echo "GROUP_NAME=$GROUP_NAME"

# Create cloud user in Entra ID
USER_ID="$(az ad user create \
  --display-name "$LAB_USER_DISPLAY" \
  --user-principal-name "$LAB_USER_UPN" \
  --password "$TEMP_PASSWORD" \
  --force-change-password-next-sign-in true \
  --query id -o tsv)"
echo "USER_ID=$USER_ID"

# Create security group
GROUP_ID="$(az ad group create \
  --display-name "$GROUP_NAME" \
  --mail-nickname "$GROUP_NAME" \
  --query id -o tsv)"
echo "GROUP_ID=$GROUP_ID"

# Add user to group
az ad group member add --group "$GROUP_ID" --member-id "$USER_ID"
echo "Added $LAB_USER_UPN to group $GROUP_NAME"

# Get RG scope ID
RG_ID="$(az group show --name "$RG_NAME" --query id -o tsv)"
echo "RG_ID=$RG_ID"

# Assign Reader role to group at RG scope
ROLE_ASSIGNMENT_ID="$(az role assignment create \
  --assignee-object-id "$GROUP_ID" \
  --assignee-principal-type Group \
  --role "Reader" \
  --scope "$RG_ID" \
  --query id -o tsv)"
echo "ROLE_ASSIGNMENT_ID=$ROLE_ASSIGNMENT_ID"
```

### 3) Validate
```bash
# Validate user and group objects
az ad user show --id "$LAB_USER_UPN" --query "{UPN:userPrincipalName,Id:id,DisplayName:displayName}" -o table
az ad group show --group "$GROUP_ID" --query "{Group:displayName,Id:id}" -o table

# Validate group membership
az ad group member list --group "$GROUP_ID" --query "[].{UPN:userPrincipalName,Id:id}" -o table

# Validate RBAC assignment at RG scope
az role assignment list \
  --assignee-object-id "$GROUP_ID" \
  --scope "$RG_ID" \
  -o table

echo "Validated group-based RBAC assignment."
```

## ARM template solution (when needed)
Not required for this lab.

## Cleanup (required)
```bash
# Remove role assignment first
az role assignment delete --ids "$ROLE_ASSIGNMENT_ID"

# Delete Entra group and user
az ad group delete --group "$GROUP_ID"
az ad user delete --id "$LAB_USER_UPN"

# Delete resource group and local env file
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: role assignment, Entra objects, and RG removed."
```

## Notes
- This lab demonstrates why group-based RBAC is preferred over direct user assignments.
- Role propagation and token refresh can take a few minutes in real environments.
