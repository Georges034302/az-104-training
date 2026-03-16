# Lab: Build in ACR and Run in ACI (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a private Azure Container Registry, build an image, and deploy it to Azure Container Instances through portal-driven workflow.

## What you will build

 [Dockerfile]
     |
     v
 [Azure Container Registry]
     |
     v
 [Container Image]
     |
     v
 [Azure Container Instance]
     |
     v
 [Public FQDN]

## Estimated time
45-60 minutes

## Cost + safety
- ACR and ACI are billable while deployed.
- Use Basic ACR and low ACI CPU/memory values for lab scope.
- In production, use managed identity and AcrPull role instead of admin credentials.

## Prerequisites
- Azure subscription with rights to create ACR and ACI resources
- Azure Portal access
- Cloud Shell access in portal

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m04acraci"
RG_NAME="${PREFIX}-${LAB}-rg"
ACR_NAME="az104m04acr001"
ACI_NAME="${PREFIX}-${LAB}-aci"
IMAGE_NAME="nginx-demo:v1"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, ACI_NAME=$ACI_NAME"
```

## Portal solution (step-by-step)
### 1) Create resource group and ACR
1. Open Resource groups and create ${RG_NAME} in ${LOCATION}.
2. Open Container registries and select Create.
3. Set:
   - Resource group: ${RG_NAME}
   - Registry name: globally unique name based on ${ACR_NAME}
   - SKU: Basic
   - Region: ${LOCATION}
4. Create the registry.
5. Open the registry > Access keys and enable Admin user for this lab.

### 2) Build image in ACR using Cloud Shell
1. Open Cloud Shell in Azure Portal.
2. Run:
```bash
source .env

cat > Dockerfile << 'DOCKEREOF'
FROM mcr.microsoft.com/oss/nginx/nginx:1.25.3
RUN echo "AZ-104 Portal ACR/ACI lab" > /usr/share/nginx/html/index.html
DOCKEREOF

az acr build \
    --registry "$ACR_NAME" \
    --image "$IMAGE_NAME" \
  .
```
3. Confirm the build succeeds.

### 3) Create ACI from the private ACR image
1. Open Container instances and select Create.
2. On Basics:
   - Resource group: ${RG_NAME}
   - Container name: ${ACI_NAME}
   - Region: ${LOCATION}
   - Image source: Azure Container Registry
3. Select your ACR and image tag nginx-demo:v1.
4. On Networking:
   - Networking type: Public
   - DNS name label: unique lower-case value
   - Port: 80
5. Create the container group.

### 4) Validate
1. Open the ACI resource and confirm state is Running.
2. Open Containers > Logs and verify startup output.
3. Copy FQDN from Overview and open it in browser.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env Dockerfile
echo "Cleanup started: $RG_NAME"
```

## Notes
- If ACI fails to pull image, re-check registry/image/tag selection and ACR admin key state.
- ACR naming must be globally unique and lowercase alphanumeric.