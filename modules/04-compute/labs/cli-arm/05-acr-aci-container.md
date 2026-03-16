# Lab: Build in ACR and Run in ACI (CLI + ARM)
> Variant: CLI + ARM lab track (Portal walkthrough omitted).

## Objective
Create an Azure Container Registry, build an image with ACR Tasks, deploy that image to Azure Container Instances, and validate runtime health and endpoint access.

## What you will build

 [Dockerfile Source]
        |
        v
 [ACR Build Task]
        |
        v
 [Image in ACR]
        |
        v
 [ACI Container Group]
        |
        v
 [Public FQDN]

## Estimated time
45-60 minutes

## Cost + safety
- ACR and ACI both incur cost while provisioned.
- Use Basic ACR and small ACI resources for lab scope.
- In production, prefer identity-based pulls rather than admin credentials.

## Prerequisites
- Azure subscription with rights to create ACR and ACI resources
- Azure CLI installed and authenticated with az login

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m04acraci"
RG_NAME="${PREFIX}-${LAB}-rg"
IMAGE_NAME="nginx-demo:v1"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME"
```

## Azure CLI solution (fully parameterized)
### 1) Create resource group and ACR
```bash
az group create --name "$RG_NAME" --location "$LOCATION"

SUFFIX="$(openssl rand -hex 3)"
ACR_NAME="$(echo "${PREFIX}${LAB}${SUFFIX}" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-50)"
ACI_NAME="${PREFIX}-${LAB}-aci"
DNS_LABEL="$(echo "${PREFIX}${LAB}${SUFFIX}aci" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]' | cut -c1-60)"

az acr create \
  --resource-group "$RG_NAME" \
  --name "$ACR_NAME" \
  --sku Basic \
  --location "$LOCATION"

ACR_LOGIN_SERVER="$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)"
echo "ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER"
```

### 2) Build image in ACR Tasks
```bash
az acr update --name "$ACR_NAME" --admin-enabled true

ACR_USER="$(az acr credential show --name "$ACR_NAME" --query username -o tsv)"
ACR_PASS="$(az acr credential show --name "$ACR_NAME" --query passwords[0].value -o tsv)"

mkdir -p app
cat > app/Dockerfile << 'DOCKEREOF'
FROM mcr.microsoft.com/oss/nginx/nginx:1.25.3
RUN echo "AZ-104 ACR to ACI lab" > /usr/share/nginx/html/index.html
DOCKEREOF

az acr build \
  --registry "$ACR_NAME" \
  --image "$IMAGE_NAME" \
  app
```

### 3) Deploy ACI from private ACR image
```bash
ACI_ID="$(az container create \
  --resource-group "$RG_NAME" \
  --name "$ACI_NAME" \
  --image "${ACR_LOGIN_SERVER}/${IMAGE_NAME}" \
  --registry-login-server "$ACR_LOGIN_SERVER" \
  --registry-username "$ACR_USER" \
  --registry-password "$ACR_PASS" \
  --dns-name-label "$DNS_LABEL" \
  --ip-address Public \
  --ports 80 \
  --query id -o tsv)"

ACI_FQDN="$(az container show \
  --resource-group "$RG_NAME" \
  --name "$ACI_NAME" \
  --query ipAddress.fqdn -o tsv)"

echo "ACI_ID=$ACI_ID"
echo "ACI_FQDN=$ACI_FQDN"
```

### 4) Validate
```bash
az container show \
  --resource-group "$RG_NAME" \
  --name "$ACI_NAME" \
  --query "{name:name,state:instanceView.state,fqdn:ipAddress.fqdn,image:containers[0].image}" \
  -o jsonc

az container logs \
  --resource-group "$RG_NAME" \
  --name "$ACI_NAME"

curl -I "http://$ACI_FQDN"
```

## ARM template solution (when needed)
Not required for this lab. Building and pushing images with runtime credentials is intentionally performed through operational CLI commands.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -rf app .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- ACR admin credentials are used only to keep the lab deterministic. For production, prefer managed identity and AcrPull role.
- If FQDN lookup takes time, wait briefly and retry validation.