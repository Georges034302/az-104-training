# AZ-104 Azure Administrator Training

> **Comprehensive, hands-on training materials for Microsoft Azure Administrator (AZ-104) certification**

This repository provides structured learning paths combining conceptual lessons with practical labs, covering all five core domains of Azure administration.

## 📋 Repository Overview

**Structure**: Each module contains conceptual lessons and hands-on labs organized by topic
- **Lessons**: Theory, architecture diagrams, and best practices
- **Labs**: Executable Azure CLI and Portal instructions with `.env` file management
- **Safety-first**: All labs include cleanup sections and use parameterized variables

**Default Configuration**:
- Region: `australiaeast`
- Environment: `.env` files for portable configuration

---

## 🎓 Training Modules

<details>
<summary><h3>Module 01: Identity & Governance</h3></summary>

**Focus**: Azure AD (Entra ID), RBAC, managed identities, and governance controls

#### 📖 Lessons
- [Entra ID Basics](modules/01-identity/lessons/01-entra-id-basics.md) - Azure Active Directory fundamentals, users, groups, and authentication
- [Role-Based Access Control (RBAC)](modules/01-identity/lessons/02-rbac.md) - Permission management with built-in and custom roles
- [Managed Identities](modules/01-identity/lessons/03-managed-identities.md) - System and user-assigned identities for secure service authentication
- [Governance: Policy, Locks & Tags](modules/01-identity/lessons/04-governance-policy-locks-tags.md) - Resource organization and compliance enforcement

#### 🧪 Labs
- [RBAC Role Assignment](modules/01-identity/labs/01-rbac-role-assignment.md) - Assign Azure roles to users and service principals
- [Managed Identity Storage Access](modules/01-identity/labs/02-managed-identity-storage-access.md) - Configure managed identity to access Azure Storage without credentials
- [Tags, Locks & Policy](modules/01-identity/labs/03-tags-lock-policy.md) - Apply resource tags, deletion locks, and Azure Policy

</details>

<details>
<summary><h3>Module 02: Virtual Networking</h3></summary>

**Focus**: VNets, subnets, NSGs, peering, routing, DNS, and load balancing

#### 📖 Lessons
- [VNet & Subnets](modules/02-networking/lessons/01-vnet-subnets.md) - Virtual networks, address spaces, and subnet segmentation
- [VNet Peering](modules/02-networking/lessons/02-vnet-peering.md) - Connect virtual networks with global and regional peering
- [Network Security Groups (NSG) & ASG](modules/02-networking/lessons/03-nsg-asg.md) - Traffic filtering with security rules and application security groups
- [Routing & User-Defined Routes (UDR)](modules/02-networking/lessons/04-routing-udr.md) - Custom route tables and network virtual appliances
- [Azure DNS](modules/02-networking/lessons/05-azure-dns.md) - Public and private DNS zones for name resolution
- [Private Endpoints](modules/02-networking/lessons/06-private-endpoints.md) - Secure PaaS services with private connectivity
- [Load Balancing](modules/02-networking/lessons/07-load-balancing.md) - Azure Load Balancer, Application Gateway, and Traffic Manager

#### 🧪 Labs
- [Create VNet, Subnets & NSG](modules/02-networking/labs/01-create-vnet-subnets-nsg.md) - Build a virtual network with security groups
- [VNet Peering Connectivity](modules/02-networking/labs/02-vnet-peering-connectivity.md) - Connect two VNets and verify cross-network communication
- [UDR Routing Simulation](modules/02-networking/labs/03-udr-routing-simulation.md) - Implement custom routes with route tables
- [Private Endpoint for Storage with DNS](modules/02-networking/labs/04-private-endpoint-storage-dns.md) - Secure blob storage with private endpoint and DNS integration
- [Basic Load Balancer](modules/02-networking/labs/05-basic-load-balancer.md) - Deploy a public load balancer with health probes

</details>

<details>
<summary><h3>Module 03: Azure Storage</h3></summary>

**Focus**: Storage accounts, blob containers, Azure Files, lifecycle policies, and security

#### 📖 Lessons
- [Storage Accounts & Redundancy](modules/03-storage/lessons/01-storage-accounts-redundancy.md) - Account types, performance tiers, and replication options (LRS, GRS, ZRS, RA-GRS)
- [Blob Storage & Lifecycle Management](modules/03-storage/lessons/02-blob-lifecycle.md) - Container management and automated tier transitions
- [Azure Files](modules/03-storage/lessons/03-azure-files.md) - SMB file shares for cloud and hybrid scenarios
- [Storage Security: SAS vs RBAC](modules/03-storage/lessons/04-storage-security-sas-rbac.md) - Shared Access Signatures and role-based access comparison

#### 🧪 Labs
- [Storage Account & Blob Container](modules/03-storage/labs/01-storage-account-blob-container.md) - Create storage account, upload and download blobs
- [Lifecycle Policy](modules/03-storage/labs/02-lifecycle-policy.md) - Automate blob tier transitions based on age
- [Azure Files Share](modules/03-storage/labs/03-azure-files-share.md) - Create and configure SMB file share with quota
- [SAS vs RBAC](modules/03-storage/labs/04-sas-vs-rbac.md) - Compare delegation methods with SAS tokens and Azure RBAC

</details>

<details>
<summary><h3>Module 04: Compute Resources</h3></summary>

**Focus**: Virtual machines, availability, scaling, App Service, and containers

#### 📖 Lessons
- [Virtual Machines](modules/04-compute/lessons/01-virtual-machines.md) - VM sizes, SKUs, images, and deployment options
- [Availability Sets & Zones](modules/04-compute/lessons/02-availability-sets-zones.md) - High availability with fault and update domains
- [Scaling](modules/04-compute/lessons/03-scaling.md) - VM Scale Sets (VMSS) and autoscaling strategies
- [App Service](modules/04-compute/lessons/04-app-service.md) - Web apps, deployment slots, and app service plans
- [Containers: ACR, ACI & ACA](modules/04-compute/lessons/05-containers-acr-aci-aca.md) - Azure Container Registry, Container Instances, and Container Apps

#### 🧪 Labs
- [Deploy a Virtual Machine](modules/04-compute/labs/01-deploy-vm.md) - Create Linux VM with VNet, NSG, and SSH access
- [VM Availability](modules/04-compute/labs/02-vm-availability.md) - Deploy VMs in an availability set for fault tolerance
- [VMSS Autoscale](modules/04-compute/labs/03-vmss-autoscale.md) - Configure VM Scale Set with CPU-based autoscaling rules
- [App Service Deploy](modules/04-compute/labs/04-app-service-deploy.md) - Create web app with Node.js runtime and app settings
- [ACR & ACI Container](modules/04-compute/labs/05-acr-aci-container.md) - Build container image in ACR and deploy to ACI

</details>

<details>
<summary><h3>Module 05: Monitoring & Backup</h3></summary>

**Focus**: Azure Monitor, Log Analytics, alerts, backup, and disaster recovery

#### 📖 Lessons
- [Azure Monitor](modules/05-monitoring/lessons/01-azure-monitor.md) - Metrics, logs, and Application Insights fundamentals
- [Log Analytics & KQL](modules/05-monitoring/lessons/02-log-analytics-kql.md) - Kusto Query Language for log analysis
- [Alerts & Action Groups](modules/05-monitoring/lessons/03-alerts-action-groups.md) - Metric and log-based alerts with notification workflows
- [Azure Backup](modules/05-monitoring/lessons/04-azure-backup.md) - Recovery Services Vault, backup policies, and retention
- [Azure Site Recovery](modules/05-monitoring/lessons/05-azure-site-recovery.md) - Disaster recovery and business continuity planning
- [Availability & Resilience](modules/05-monitoring/lessons/06-availability-resilience.md) - SLA calculations and resilience strategies

#### 🧪 Labs
- [Enable VM Insights](modules/05-monitoring/labs/01-enable-vm-insights.md) - Deploy Log Analytics workspace and configure VM monitoring
- [Create Alert & Action Group](modules/05-monitoring/labs/02-create-alert-action-group.md) - Set up CPU alert with email notification
- [Backup & Restore VM](modules/05-monitoring/labs/03-backup-and-restore-vm.md) - Configure Recovery Services Vault and VM backup policy

</details>

---

## 🚀 Getting Started

### One-Time Setup

Run this script to install all required tools and authenticate with Azure:

```bash
./shared/scripts/az_login.sh
```

**What it does:**
- ✅ Installs Azure CLI (if not present)
- ✅ Installs Bicep CLI (for infrastructure as code)
- ✅ Installs jq (for JSON parsing)
- ✅ Logs you into Azure
- ✅ Displays your active subscription

> **Note**: You only need to run this once per environment. If already logged in, just skip this step.

---

### Best Practices

✅ **Before starting**: Run [`./shared/scripts/az_login.sh`](shared/scripts/az_login.sh) to set up your environment  
✅ **Read first**: Review Portal instructions before running CLI commands  
✅ **Understand**: Know what each command does before executing  
✅ **Monitor costs**: Check Azure Portal regularly to avoid unexpected charges
✅ Use `.env` files for portable lab configuration (add .env to .gitignore)
✅ **Clean up**: Always delete lab resources after completion (including the .env files)
> **Tip**: To see all your lab resource groups, run:
> ```bash
> az group list --query "[?starts_with(name,'az104-')].{Name:name,Location:location}" -o table
> ```

---

## � Repository Structure

```
.
├── README.md
├── docs/
│   ├── cost-safety.md
│   ├── naming-standards.md
│   ├── prerequisites.md
│   └── toc.md
├── modules/
│   ├── 01-identity/
│   │   ├── labs/
│   │   │   ├── managed-identity-storage-access.md
│   │   │   ├── rbac-role-assignment.md
│   │   │   └── tags-lock-policy.md
│   │   └── lessons/
│   │       ├── entra-id-basics.md
│   │       ├── governance-policy-locks-tags.md
│   │       ├── managed-identities.md
│   │       └── rbac.md
│   ├── 02-networking/
│   │   ├── labs/
│   │   │   ├── basic-load-balancer.md
│   │   │   ├── create-vnet-subnets-nsg.md
│   │   │   ├── private-endpoint-storage-dns.md
│   │   │   ├── udr-routing-simulation.md
│   │   │   └── vnet-peering-connectivity.md
│   │   └── lessons/
│   │       ├── azure-dns.md
│   │       ├── load-balancing.md
│   │       ├── nsg-asg.md
│   │       ├── private-endpoints.md
│   │       ├── routing-udr.md
│   │       ├── vnet-peering.md
│   │       └── vnet-subnets.md
│   ├── 03-storage/
│   │   ├── labs/
│   │   │   ├── azure-files-share.md
│   │   │   ├── lifecycle-policy.md
│   │   │   ├── sas-vs-rbac.md
│   │   │   └── storage-account-blob-container.md
│   │   └── lessons/
│   │       ├── azure-files.md
│   │       ├── blob-lifecycle.md
│   │       ├── storage-accounts-redundancy.md
│   │       └── storage-security-sas-rbac.md
│   ├── 04-compute/
│   │   ├── labs/
│   │   │   ├── acr-aci-container.md
│   │   │   ├── app-service-deploy.md
│   │   │   ├── deploy-vm.md
│   │   │   ├── vm-availability.md
│   │   │   └── vmss-autoscale.md
│   │   └── lessons/
│   │       ├── app-service.md
│   │       ├── availability-sets-zones.md
│   │       ├── containers-acr-aci-aca.md
│   │       ├── scaling.md
│   │       └── virtual-machines.md
│   └── 05-monitoring/
│       ├── labs/
│       │   ├── backup-and-restore-vm.md
│       │   ├── create-alert-action-group.md
│       │   └── enable-vm-insights.md
│       └── lessons/
│           ├── alerts-action-groups.md
│           ├── availability-resilience.md
│           ├── azure-backup.md
│           ├── azure-monitor.md
│           ├── azure-site-recovery.md
│           └── log-analytics-kql.md
└── shared/
    └── scripts/
        └── az_login.sh

📊 5 modules • 26 lessons • 20 labs • 57 total files
```

---

## 🛡️ Cost Safety

All labs are designed with cost optimization:
- Small VM sizes (B1s tier)
- Short-lived resources
- Async deletion (`--no-wait`)
- Default to australiaeast region
- `.env` files excluded from version control

---

## 🎯 Exam Preparation

These materials align with the official AZ-104 exam domains:
- **Identity & Governance** (15-20%)
- **Storage** (15-20%)
- **Compute** (20-25%)
- **Networking** (25-30%)
- **Monitoring & Backup** (10-15%)

> **Good luck with your certification!** 🎓

---

## 🧑‍🏫 Author: **Georges Bou Ghantous**

AZ-104 certification training materials with 26 lessons and 20 hands-on labs covering all five Azure Administrator exam domains.

---