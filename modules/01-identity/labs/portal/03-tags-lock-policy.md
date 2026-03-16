# Lab: Apply Tags + Resource Lock + Basic Policy Assignment
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a RG, apply tags, add a Delete lock, and assign a simple policy (Audit) at RG scope. Validate compliance state.

## What you will build

 [Resource Group]
   |      |      |
   v      v      v
 [Tags] [Delete Lock] [Policy Assignment]
                        |
                        v
               [Audit Non-compliance]

## Estimated time
30–45 minutes

## Cost + safety
- All resources are created in a **dedicated Resource Group** for this lab and can be deleted at the end.
- Default region: **australiaeast** (change if needed).

## Prerequisites
- Azure subscription with permission to create resources
- Azure CLI installed and authenticated (`az login`)
- (Optional) Azure Portal access

## Setup: Create environment file
```bash
cat > .env << 'EOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m01-governance"
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
3. In the resource group, select **Tags** from the left menu.
  - Add tags: `owner=student`, `env=dev`, `course=az104`
  - Click **Save**.
4. In the resource group, select **Locks** from the left menu.
  - Click **Add**
  - Lock name: `${RG_NAME}-delete-lock`
  - Lock type: **Delete**
  - Notes: (optional)
  - Click **OK**.
5. In the resource group, select **Policies** from the left menu.
  - Click **Assign policy**
  - Policy definition: search for **Allowed locations**
  - Assignment name: `${RG_NAME}-allowed-locations`
  - Allowed locations: `australiaeast`
  - Click **Review + create** > **Create**.
6. To validate:
  - In **Policies**, go to **Compliance** and confirm the assignment appears and is evaluated.



## Cleanup (required)
```bash
# Delete the resource group and all its resources asynchronously
az group delete \
  --name "$RG_NAME" \
  --yes \
  --no-wait
echo "Deleted RG: $RG_NAME (async)"

# Remove the environment file
rm -f .env
echo "Cleaned up environment file"
```

## Notes
- Every CLI command that returns an ID/URL is captured into a **variable** and echoed.
- If a command returns JSON, use `--query ... -o tsv` for clean variable assignment.