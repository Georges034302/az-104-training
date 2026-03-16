# Lab: Basic Public Load Balancer (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a Standard public load balancer with frontend IP, backend pool, health probe, and load-balancing rule. Validate control-plane configuration.

## What you will build

 [Public IP] ---> [Standard Load Balancer]
                     |          |
                     v          v
                [Health Probe] [Backend Pool]

## Estimated time
30-45 minutes

## Cost + safety
- Resource group isolation enables complete cleanup.
- This lab focuses on LB objects and can avoid VM deployment for lower cost.

## Prerequisites
- Azure Portal access
- Permission to create networking resources

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m02-lb"
RG_NAME="${PREFIX}-${LAB}-rg"
LB_NAME="${PREFIX}-${LAB}-lb"
PIP_NAME="${PREFIX}-${LAB}-pip"
ENVEOF

source .env
echo "Loaded: $RG_NAME, $LB_NAME, $PIP_NAME"
```

## Portal solution (step-by-step)
### 1) Create resource group
1. Open **Resource groups** > **Create**.
2. Set name `${RG_NAME}` and region `${LOCATION}`.
3. Select **Create**.

### 2) Create public IP
1. Open **Public IP addresses** > **Create**.
2. Set:
   - Resource group: `${RG_NAME}`
   - Name: `${PIP_NAME}`
   - SKU: **Standard**
   - Assignment: **Static**
   - Region: `${LOCATION}`
3. Select **Review + create** > **Create**.

### 3) Create standard load balancer
1. Open **Load balancers** > **Create**.
2. In **Basics**:
   - Type: **Public**
   - SKU: **Standard**
   - Name: `${LB_NAME}`
   - Region: `${LOCATION}`
   - Resource group: `${RG_NAME}`
3. In **Frontend IP configuration**:
   - Name: `fe-public`
   - Public IP address: `${PIP_NAME}`
4. Select **Review + create** > **Create**.

### 4) Create backend pool
1. Open `${LB_NAME}` > **Backend pools** > **+ Add**.
2. Name: `be-pool`.
3. Backend type: **NIC** (or Virtual Machine depending on portal version).
4. Save.

### 5) Create health probe
1. Open `${LB_NAME}` > **Health probes** > **+ Add**.
2. Configure:
   - Name: `tcp-80-probe`
   - Protocol: **TCP**
   - Port: `80`
   - Interval: default
3. Save.

### 6) Create load-balancing rule
1. Open `${LB_NAME}` > **Load balancing rules** > **+ Add**.
2. Configure:
   - Name: `http-rule`
   - Frontend IP address: `fe-public`
   - Protocol: **TCP**
   - Frontend port: `80`
   - Backend port: `80`
   - Backend pool: `be-pool`
   - Health probe: `tcp-80-probe`
3. Save.

### 7) Validate
1. In `${LB_NAME}` overview, confirm frontend configuration exists.
2. In **Backend pools**, verify `be-pool` exists.
3. In **Health probes**, verify `tcp-80-probe` is present.
4. In **Load balancing rules**, verify `http-rule` exists.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- Without healthy backend targets, the LB rule will not forward live traffic.
- Traffic Manager and Application Gateway are separate services; this lab is Azure Load Balancer only.
