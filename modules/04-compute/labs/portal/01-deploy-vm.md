# Lab: Deploy a Linux VM with VNet and NSG (Portal)
> Variant: Portal lab track (CLI/ARM walkthrough omitted).

## Objective
Create a Linux VM in Azure Portal with dedicated network resources and controlled SSH access.

## What you will build

 [Client IP]
    |
    v
 [NSG Allow SSH 22]
    |
    v
 [Subnet] ---> [NIC] ---> [Linux VM] ---> [Public IP]

## Estimated time
45-60 minutes

## Cost + safety
- Use a small VM size and delete resources after the lab.
- Restrict SSH source where possible.

## Prerequisites
- Azure subscription with rights to create compute and network resources
- Azure Portal access

## Setup: create environment file
```bash
cat > .env << 'ENVEOF'
LOCATION="australiaeast"
PREFIX="az104"
LAB="m04vm"
RG_NAME="${PREFIX}-${LAB}-rg"
VNET_NAME="${PREFIX}-${LAB}-vnet"
SUBNET_NAME="vm"
NSG_NAME="${PREFIX}-${LAB}-nsg"
VM_NAME="${PREFIX}-${LAB}-vm"
ENVEOF

source .env
echo "Loaded: RG_NAME=$RG_NAME, VM_NAME=$VM_NAME"
```

## Portal solution (step-by-step)
### 1) Create resource group
1. Open Resource groups and select Create.
2. Set Resource group name to ${RG_NAME} and Region to ${LOCATION}.
3. Select Review + create, then Create.

### 2) Create virtual network and subnet
1. Open Virtual networks and select Create.
2. On Basics:
  - Resource group: ${RG_NAME}
  - Name: ${VNET_NAME}
  - Region: ${LOCATION}
3. On IP addresses:
  - Address space: 10.60.0.0/16
  - Subnet name: ${SUBNET_NAME}
  - Subnet range: 10.60.2.0/24
4. Select Review + create, then Create.

### 3) Create NSG and inbound SSH rule
1. Open Network security groups and select Create.
2. Set:
  - Resource group: ${RG_NAME}
  - Name: ${NSG_NAME}
  - Region: ${LOCATION}
3. Create the NSG.
4. Open ${NSG_NAME} > Inbound security rules > Add.
5. Configure:
  - Source: Any (or your public IP range)
  - Source port ranges: *
  - Destination: Any
  - Service: SSH
  - Action: Allow
  - Priority: 1000
  - Name: Allow-SSH
6. Select Add.

### 4) Associate NSG to subnet
1. Open Virtual networks > ${VNET_NAME} > Subnets.
2. Select subnet ${SUBNET_NAME}.
3. In Network security group, choose ${NSG_NAME}.
4. Select Save.

### 5) Create Linux VM
1. Open Virtual machines and select Create > Azure virtual machine.
2. On Basics:
  - Resource group: ${RG_NAME}
  - VM name: ${VM_NAME}
  - Region: ${LOCATION}
  - Image: Ubuntu Server 22.04 LTS
  - Size: Standard_B1s (or closest available)
  - Authentication type: SSH public key
3. On Networking:
  - Virtual network: ${VNET_NAME}
  - Subnet: ${SUBNET_NAME}
  - Public inbound ports: None
4. Select Review + create, then Create.

### 6) Validate
1. Open Virtual machines > ${VM_NAME}.
2. Confirm Provisioning state is Succeeded and VM status is Running.
3. In Networking, verify NIC is in subnet ${SUBNET_NAME}.
4. Verify subnet NSG association points to ${NSG_NAME}.

## Cleanup (required)
```bash
az group delete --name "$RG_NAME" --yes --no-wait
rm -f .env
echo "Cleanup started: $RG_NAME"
```

## Notes
- Public inbound ports were left as None on VM creation because SSH is controlled through the subnet NSG rule.
- In production, replace broad source rules with your management IP range.