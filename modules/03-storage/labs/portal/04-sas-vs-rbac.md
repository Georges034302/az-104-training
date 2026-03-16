# Lab: SAS vs RBAC for Blob Access (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a storage account and private blob container, upload a sample blob, generate a short-lived SAS token for delegated access, and assign a Blob Data role in Azure RBAC to compare the two access models.

## What you will build

 [Storage Account]
   /        \
  v          v
 [SAS Token] [RBAC Data Role]
    \      /
     v    v
  [Blob Container]

## Estimated time
35-45 minutes

## Cost + safety
- The lab uses a single storage account and small blob upload.
- SAS tokens should be kept short-lived and treated as secrets.
- RBAC propagation can take several minutes.

## Prerequisites
- Azure subscription with permission to create storage resources and assign roles
- Azure Portal access
- A target user, group, or service principal that can receive the RBAC assignment

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m03sasrbac"
RG_NAME="${PREFIX}-${LAB}-rg"
STG_NAME="az104m03sas001"
CONTAINER_NAME="sasdata"
ROLE_NAME="Storage Blob Data Reader"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, STG_NAME=$STG_NAME, CONTAINER_NAME=$CONTAINER_NAME"
```

## Portal solution (step-by-step)
### 1) Create the resource group and storage account
1. Open **Resource groups** > **Create** and create `${RG_NAME}` in `${LOCATION}`.
2. Open **Storage accounts** > **Create**.
3. Set:
  - Resource group: `${RG_NAME}`
  - Storage account name: choose a globally unique variation of `${STG_NAME}`
  - Region: `${LOCATION}`
  - Performance: **Standard**
  - Redundancy: **Locally-redundant storage (LRS)**
4. Select **Review + create**, then **Create**.

### 2) Create a private container and upload a blob
1. Open the storage account.
2. Go to **Containers** under **Data storage**.
3. Create container `${CONTAINER_NAME}` with anonymous access disabled.
4. Open the container and upload a small text file.

### 3) Generate a service SAS
1. Open container `${CONTAINER_NAME}`.
2. Select **Generate SAS** or the equivalent shared access signature action in your portal view.
3. Set:
  - Allowed permissions: **Read** and **List**
  - Start time: current time or slightly earlier if your portal requires it
  - Expiry time: about 30 minutes from now
  - Allowed protocols: **HTTPS only**
4. Generate the SAS token.
5. Copy the generated token or URL and note that it grants time-bound delegated access without requiring Azure sign-in.

### 4) Assign RBAC at storage account scope
1. Return to the storage account overview.
2. Open **Access control (IAM)** > **Add** > **Add role assignment**.
3. Select role `${ROLE_NAME}`.
4. Choose the target user, group, or service principal.
5. Complete the assignment.

### 5) Validate
1. Confirm the SAS output includes an expiry time and permission set.
2. In **Access control (IAM)**, confirm the selected principal now has `${ROLE_NAME}` at the storage account scope.
3. Note the operational difference:
  - SAS is a signed delegated token
  - RBAC is identity-based authorization evaluated at request time

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- If you test RBAC immediately, allow time for propagation before concluding access is missing.
- Prefer Microsoft Entra plus RBAC for normal operational access, and use SAS for tightly scoped delegation when required.