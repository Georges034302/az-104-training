# AZ-104 Azure Administrator Training

> **Comprehensive, hands-on training materials for Microsoft Azure Administrator (AZ-104) certification**

This repository provides structured learning paths combining conceptual lessons with practical labs, covering all five core domains of Azure administration.

## 📋 Repository Overview


**Structure**: Each module contains conceptual lessons and hands-on labs organized by topic
- **Lessons**: Theory, text-based architecture diagrams, and best practices
- **Labs**: Two tracks per module: `labs/cli-arm/` and `labs/portal/`
- **Parameterization**: All labs use variables and `.env` files for portable, reusable configuration
- **Cleanup**: Every lab includes explicit cleanup steps (e.g., `az group delete`, `rm -f .env`)
- **Portal Labs**: All portal labs are written as detailed, step-by-step instructions (not just high-level)

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
- [Azure Policy](modules/01-identity/lessons/04-azure-policy.md) - Policy definitions, compliance evaluation, and enforcement for governance
- [Resource Management: Locks & Tags](modules/01-identity/lessons/05-resource-management-locks-tags.md) - Resource protection with locks and organization with tags

#### 🧪 Labs
- [RBAC Role Assignment (CLI + ARM)](modules/01-identity/labs/cli-arm/01-rbac-role-assignment.md) | [Portal](modules/01-identity/labs/portal/01-rbac-role-assignment.md) - Assign Azure roles to users and service principals
- [Managed Identity Storage Access (CLI + ARM)](modules/01-identity/labs/cli-arm/02-managed-identity-storage-access.md) | [Portal](modules/01-identity/labs/portal/02-managed-identity-storage-access.md) - Configure managed identity to access Azure Storage without credentials
- [Tags, Locks & Policy (CLI + ARM)](modules/01-identity/labs/cli-arm/03-tags-lock-policy.md) | [Portal](modules/01-identity/labs/portal/03-tags-lock-policy.md) - Apply resource tags, deletion locks, and Azure Policy
- [Entra Users, Groups & Group-Based RBAC (CLI + ARM)](modules/01-identity/labs/cli-arm/04-entra-users-groups-rbac.md) | [Portal](modules/01-identity/labs/portal/04-entra-users-groups-rbac.md) - Create Entra users/groups and assign RBAC through group membership

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
- [Create VNet, Subnets & NSG (CLI + ARM)](modules/02-networking/labs/cli-arm/01-create-vnet-subnets-nsg.md) | [Portal](modules/02-networking/labs/portal/01-create-vnet-subnets-nsg.md) - Build segmented VNet networking with NSG association and rule validation
- [VNet Peering Connectivity (CLI + ARM)](modules/02-networking/labs/cli-arm/02-vnet-peering-connectivity.md) | [Portal](modules/02-networking/labs/portal/02-vnet-peering-connectivity.md) - Configure bidirectional peering and validate connected state
- [UDR Routing Simulation (CLI + ARM)](modules/02-networking/labs/cli-arm/03-udr-routing-simulation.md) | [Portal](modules/02-networking/labs/portal/03-udr-routing-simulation.md) - Create route tables, custom routes, and subnet associations
- [Private Endpoint for Storage with DNS (CLI + ARM)](modules/02-networking/labs/cli-arm/04-private-endpoint-storage-dns.md) | [Portal](modules/02-networking/labs/portal/04-private-endpoint-storage-dns.md) - Deploy private endpoint + private DNS integration for blob access
- [Basic Load Balancer (CLI + ARM)](modules/02-networking/labs/cli-arm/05-basic-load-balancer.md) | [Portal](modules/02-networking/labs/portal/05-basic-load-balancer.md) - Build Standard public load balancer frontend, probe, rule, and backend pool setup

**Module 02 lab quality baseline**:
- CLI + ARM labs are fully parameterized with `.env` and include validation + cleanup.
- Portal labs are detailed step-by-step and aligned with equivalent CLI outcomes.
- Networking diagrams in labs are text-based (no Mermaid).

</details>

<details>
<summary><h3>Module 03: Azure Storage</h3></summary>

**Focus**: Storage account design, redundancy, blob lifecycle, Azure Files, and secure data access

#### 📖 Lessons
- [Storage Accounts & Redundancy](modules/03-storage/lessons/01-storage-accounts-redundancy.md) - Storage account capabilities, performance models, and redundancy choices including LRS, ZRS, GRS, and GZRS variants
- [Blob Storage & Lifecycle Management](modules/03-storage/lessons/02-blob-lifecycle.md) - Blob types, access tiers, lifecycle rules, and data protection controls
- [Azure Files](modules/03-storage/lessons/03-azure-files.md) - Azure Files architecture, SMB/NFS considerations, share tiers, and hybrid file scenarios
- [Storage Security: SAS vs RBAC](modules/03-storage/lessons/04-storage-security-sas-rbac.md) - Data-plane authorization with Azure RBAC, SAS, and supporting network controls

#### 🧪 Labs
- [Storage Account & Blob Container (CLI + ARM)](modules/03-storage/labs/cli-arm/01-storage-account-blob-container.md) | [Portal](modules/03-storage/labs/portal/01-storage-account-blob-container.md) - Create a private blob container, upload content, and validate download flow
- [Lifecycle Policy (CLI + ARM)](modules/03-storage/labs/cli-arm/02-lifecycle-policy.md) | [Portal](modules/03-storage/labs/portal/02-lifecycle-policy.md) - Configure and validate a lifecycle rule that moves block blobs to Cool storage
- [Azure Files Share (CLI + ARM)](modules/03-storage/labs/cli-arm/03-azure-files-share.md) | [Portal](modules/03-storage/labs/portal/03-azure-files-share.md) - Create an SMB-based Azure file share, set quota, and validate file upload
- [SAS vs RBAC (CLI + ARM)](modules/03-storage/labs/cli-arm/04-sas-vs-rbac.md) | [Portal](modules/03-storage/labs/portal/04-sas-vs-rbac.md) - Compare delegated SAS access with identity-based Azure RBAC authorization

**Module 03 lab quality baseline**:
- CLI + ARM labs are fully parameterized with `.env` and include validation + cleanup.
- Portal labs are detailed step-by-step and aligned with equivalent CLI outcomes.
- Storage lab diagrams are text-based (no Mermaid).

</details>

<details>
<summary><h3>Module 04: Compute Resources</h3></summary>

**Focus**: VM operations, availability design, scaling strategy, App Service administration, and container runtimes

#### 📖 Lessons
- [Virtual Machines](modules/04-compute/lessons/01-virtual-machines.md) - VM resource model, lifecycle states, dependency troubleshooting, and secure operations
- [Availability Sets & Zones](modules/04-compute/lessons/02-availability-sets-zones.md) - Availability set versus zonal architecture and resilience trade-offs
- [Scaling](modules/04-compute/lessons/03-scaling.md) - Scale up/down versus out/in, VMSS autoscale policy design, and App Service plan scaling semantics
- [App Service](modules/04-compute/lessons/04-app-service.md) - Plan tiers, app configuration, deployment slots, and networking behavior
- [Containers: ACR, ACI & ACA](modules/04-compute/lessons/05-containers-acr-aci-aca.md) - Image registry workflows, runtime selection, and secure image pull patterns

#### 🧪 Labs
- [Deploy a Virtual Machine (CLI + ARM)](modules/04-compute/labs/cli-arm/01-deploy-vm.md) | [Portal](modules/04-compute/labs/portal/01-deploy-vm.md) - Deploy Linux VM with subnet-level NSG control and runtime/network validation
- [VM Availability (CLI + ARM)](modules/04-compute/labs/cli-arm/02-vm-availability.md) | [Portal](modules/04-compute/labs/portal/02-vm-availability.md) - Deploy two VMs in one availability set and validate domain-aware placement
- [VMSS Autoscale (CLI + ARM)](modules/04-compute/labs/cli-arm/03-vmss-autoscale.md) | [Portal](modules/04-compute/labs/portal/03-vmss-autoscale.md) - Configure bounded CPU-based autoscale policies for VM Scale Sets
- [App Service Deploy (CLI + ARM)](modules/04-compute/labs/cli-arm/04-app-service-deploy.md) | [Portal](modules/04-compute/labs/portal/04-app-service-deploy.md) - Create App Service plan + web app and verify configuration/runtime endpoint behavior
- [ACR & ACI Container (CLI + ARM)](modules/04-compute/labs/cli-arm/05-acr-aci-container.md) | [Portal](modules/04-compute/labs/portal/05-acr-aci-container.md) - Build in ACR and deploy to ACI with private image pull validation

**Module 04 lab quality baseline**:
- CLI + ARM labs are fully parameterized with `.env` and include validation + cleanup.
- Portal labs are detailed step-by-step and aligned with equivalent CLI outcomes.
- Compute lab diagrams are text-based (no Mermaid).

</details>

<details>
<summary><h3>Module 05: Monitoring & Backup</h3></summary>

**Focus**: Azure Monitor observability, operational alerting, backup recoverability, and resilience planning

#### 📖 Lessons
- [Azure Monitor Foundations](modules/05-monitoring/lessons/01-azure-monitor.md) - Signal taxonomy, data routing patterns, and troubleshooting workflow across metrics, activity logs, and resource logs
- [Log Analytics & KQL](modules/05-monitoring/lessons/02-log-analytics-kql.md) - Workspace/table model, query design, and collection-path precision for operational investigation
- [Alerts & Action Groups](modules/05-monitoring/lessons/03-alerts-action-groups.md) - Alert type selection, noise-control strategy, and action routing design for reliable response
- [Azure Backup](modules/05-monitoring/lessons/04-azure-backup.md) - Vault/policy/recovery-point behavior, restore paths, and governance practices
- [Azure Site Recovery](modules/05-monitoring/lessons/05-azure-site-recovery.md) - Replication, failover/failback lifecycle, and DR validation expectations
- [Availability & Resilience](modules/05-monitoring/lessons/06-availability-resilience.md) - SLA, RTO/RPO design reasoning and HA/Backup/DR decision alignment

#### 🧪 Labs
- [Enable VM Insights (CLI + ARM)](modules/05-monitoring/labs/cli-arm/01-enable-vm-insights.md) | [Portal](modules/05-monitoring/labs/portal/01-enable-vm-insights.md) - Build VM + Log Analytics pipeline, onboard VM Insights, and validate Heartbeat/KQL ingestion
- [Create Alert & Action Group (CLI + ARM)](modules/05-monitoring/labs/cli-arm/02-create-alert-action-group.md) | [Portal](modules/05-monitoring/labs/portal/02-create-alert-action-group.md) - Create reusable Action Group and CPU metric alert with rule/action validation
- [Backup & Restore VM (CLI + ARM)](modules/05-monitoring/labs/cli-arm/03-backup-and-restore-vm.md) | [Portal](modules/05-monitoring/labs/portal/03-backup-and-restore-vm.md) - Enable VM backup in Recovery Services vault and validate restore workflow safely
- [Service Health + Resource Health Alerts (CLI + ARM)](modules/05-monitoring/labs/cli-arm/04-service-health-resource-health-alerts.md) | [Portal](modules/05-monitoring/labs/portal/04-service-health-resource-health-alerts.md) - Configure subscription-scope Activity Log alerts and shared health notification routing

**Module 05 lab quality baseline**:
- CLI + ARM labs are fully parameterized with `.env` and include explicit validation + cleanup.
- Portal labs are detailed step-by-step and aligned with equivalent CLI outcomes.
- Monitoring diagrams in lessons/labs are text-based (no Mermaid).

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

## 📁 Repository Structure

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
│   │   ├── README.md
│   │   ├── labs/
│   │   │   ├── cli-arm/
│   │   │   │   ├── 01-rbac-role-assignment.md
│   │   │   │   ├── 02-managed-identity-storage-access.md
│   │   │   │   ├── 03-tags-lock-policy.md
│   │   │   │   └── 04-entra-users-groups-rbac.md
│   │   │   └── portal/
│   │   │       ├── 01-rbac-role-assignment.md
│   │   │       ├── 02-managed-identity-storage-access.md
│   │   │       ├── 03-tags-lock-policy.md
│   │   │       └── 04-entra-users-groups-rbac.md
│   │   └── lessons/
│   │       ├── 01-entra-id-basics.md
│   │       ├── 02-rbac.md
│   │       ├── 03-managed-identities.md
│   │       ├── 04-azure-policy.md
│   │       └── 05-resource-management-locks-tags.md
│   ├── 02-networking/
│   │   ├── README.md
│   │   ├── labs/
│   │   │   ├── cli-arm/
│   │   │   │   ├── 01-create-vnet-subnets-nsg.md
│   │   │   │   ├── 02-vnet-peering-connectivity.md
│   │   │   │   ├── 03-udr-routing-simulation.md
│   │   │   │   ├── 04-private-endpoint-storage-dns.md
│   │   │   │   └── 05-basic-load-balancer.md
│   │   │   └── portal/
│   │   │       ├── 01-create-vnet-subnets-nsg.md
│   │   │       ├── 02-vnet-peering-connectivity.md
│   │   │       ├── 03-udr-routing-simulation.md
│   │   │       ├── 04-private-endpoint-storage-dns.md
│   │   │       └── 05-basic-load-balancer.md
│   │   └── lessons/
│   │       ├── 01-vnet-subnets.md
│   │       ├── 02-vnet-peering.md
│   │       ├── 03-nsg-asg.md
│   │       ├── 04-routing-udr.md
│   │       ├── 05-azure-dns.md
│   │       ├── 06-private-endpoints.md
│   │       └── 07-load-balancing.md
│   ├── 03-storage/
│   │   ├── README.md
│   │   ├── labs/
│   │   │   ├── cli-arm/
│   │   │   │   ├── 01-storage-account-blob-container.md
│   │   │   │   ├── 02-lifecycle-policy.md
│   │   │   │   ├── 03-azure-files-share.md
│   │   │   │   └── 04-sas-vs-rbac.md
│   │   │   └── portal/
│   │   │       ├── 01-storage-account-blob-container.md
│   │   │       ├── 02-lifecycle-policy.md
│   │   │       ├── 03-azure-files-share.md
│   │   │       └── 04-sas-vs-rbac.md
│   │   └── lessons/
│   │       ├── 01-storage-accounts-redundancy.md
│   │       ├── 02-blob-lifecycle.md
│   │       ├── 03-azure-files.md
│   │       └── 04-storage-security-sas-rbac.md
│   ├── 04-compute/
│   │   ├── README.md
│   │   ├── labs/
│   │   │   ├── cli-arm/
│   │   │   │   ├── 01-deploy-vm.md
│   │   │   │   ├── 02-vm-availability.md
│   │   │   │   ├── 03-vmss-autoscale.md
│   │   │   │   ├── 04-app-service-deploy.md
│   │   │   │   └── 05-acr-aci-container.md
│   │   │   └── portal/
│   │   │       ├── 01-deploy-vm.md
│   │   │       ├── 02-vm-availability.md
│   │   │       ├── 03-vmss-autoscale.md
│   │   │       ├── 04-app-service-deploy.md
│   │   │       └── 05-acr-aci-container.md
│   │   └── lessons/
│   │       ├── 01-virtual-machines.md
│   │       ├── 02-availability-sets-zones.md
│   │       ├── 03-scaling.md
│   │       ├── 04-app-service.md
│   │       └── 05-containers-acr-aci-aca.md
│   └── 05-monitoring/
│       ├── README.md
│       ├── labs/
│       │   ├── cli-arm/
│       │   │   ├── 01-enable-vm-insights.md
│       │   │   ├── 02-create-alert-action-group.md
│       │   │   ├── 03-backup-and-restore-vm.md
│       │   │   └── 04-service-health-resource-health-alerts.md
│       │   └── portal/
│       │       ├── 01-enable-vm-insights.md
│       │       ├── 02-create-alert-action-group.md
│       │       ├── 03-backup-and-restore-vm.md
│       │       └── 04-service-health-resource-health-alerts.md
│       └── lessons/
│           ├── 01-azure-monitor.md
│           ├── 02-log-analytics-kql.md
│           ├── 03-alerts-action-groups.md
│           ├── 04-azure-backup.md
│           ├── 05-azure-site-recovery.md
│           └── 06-availability-resilience.md
└── shared/
    └── scripts/
        └── az_login.sh

📊 5 modules • 27 lessons • 44 labs (22 CLI+ARM + 22 Portal) • 82 total files
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

AZ-104 certification training materials with 27 lessons and 44 hands-on lab guides (22 CLI+ARM and 22 Portal) covering all five Azure Administrator exam domains.

---
