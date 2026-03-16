# Table of Contents

## Module 1 — Identity & Governance
### Lessons
1. [Entra ID Basics](../modules/01-identity/lessons/01-entra-id-basics.md)
2. [RBAC Fundamentals](../modules/01-identity/lessons/02-rbac.md)
3. [Managed Identities](../modules/01-identity/lessons/03-managed-identities.md)
4. [Azure Policy](../modules/01-identity/lessons/04-azure-policy.md)
5. [Resource Management: Locks & Tags](../modules/01-identity/lessons/05-resource-management-locks-tags.md)

### Labs
1. [RBAC Role Assignment (CLI + ARM)](../modules/01-identity/labs/cli-arm/01-rbac-role-assignment.md) | [Portal](../modules/01-identity/labs/portal/01-rbac-role-assignment.md)
2. [Managed Identity Access to Storage (CLI + ARM)](../modules/01-identity/labs/cli-arm/02-managed-identity-storage-access.md) | [Portal](../modules/01-identity/labs/portal/02-managed-identity-storage-access.md)
3. [Apply Tags + Lock + Policy (CLI + ARM)](../modules/01-identity/labs/cli-arm/03-tags-lock-policy.md) | [Portal](../modules/01-identity/labs/portal/03-tags-lock-policy.md)
4. [Entra Users + Groups + Group-Based RBAC (CLI + ARM)](../modules/01-identity/labs/cli-arm/04-entra-users-groups-rbac.md) | [Portal](../modules/01-identity/labs/portal/04-entra-users-groups-rbac.md)

## Module 2 — Networking
### Lessons
1. [VNets and Subnets](../modules/02-networking/lessons/01-vnet-subnets.md)
2. [VNet Peering](../modules/02-networking/lessons/02-vnet-peering.md)
3. [NSGs and ASGs](../modules/02-networking/lessons/03-nsg-asg.md)
4. [Routing and UDR](../modules/02-networking/lessons/04-routing-udr.md)
5. [Azure DNS: Public and Private](../modules/02-networking/lessons/05-azure-dns.md)
6. [Private Endpoints vs Service Endpoints](../modules/02-networking/lessons/06-private-endpoints.md)
7. [Load Balancing Overview](../modules/02-networking/lessons/07-load-balancing.md)

### Labs
1. [Create VNet + Subnets + NSG (CLI + ARM)](../modules/02-networking/labs/cli-arm/01-create-vnet-subnets-nsg.md) | [Portal](../modules/02-networking/labs/portal/01-create-vnet-subnets-nsg.md)
2. [VNet Peering and Test Connectivity (CLI + ARM)](../modules/02-networking/labs/cli-arm/02-vnet-peering-connectivity.md) | [Portal](../modules/02-networking/labs/portal/02-vnet-peering-connectivity.md)
3. [UDR Routing Simulation (CLI + ARM)](../modules/02-networking/labs/cli-arm/03-udr-routing-simulation.md) | [Portal](../modules/02-networking/labs/portal/03-udr-routing-simulation.md)
4. [Private Endpoint to Storage + Private DNS (CLI + ARM)](../modules/02-networking/labs/cli-arm/04-private-endpoint-storage-dns.md) | [Portal](../modules/02-networking/labs/portal/04-private-endpoint-storage-dns.md)
5. [Basic Load Balancer (CLI + ARM)](../modules/02-networking/labs/cli-arm/05-basic-load-balancer.md) | [Portal](../modules/02-networking/labs/portal/05-basic-load-balancer.md)

## Module 3 — Storage
### Lessons
1. [Storage Accounts + Redundancy](../modules/03-storage/lessons/01-storage-accounts-redundancy.md)
2. [Blob Storage + Lifecycle](../modules/03-storage/lessons/02-blob-lifecycle.md)
3. [Azure Files](../modules/03-storage/lessons/03-azure-files.md)
4. [Storage Security: SAS vs RBAC](../modules/03-storage/lessons/04-storage-security-sas-rbac.md)

### Labs
1. [Storage Account + Blob Container (CLI + ARM)](../modules/03-storage/labs/cli-arm/01-storage-account-blob-container.md) | [Portal](../modules/03-storage/labs/portal/01-storage-account-blob-container.md)
2. [Lifecycle Management Policy (CLI + ARM)](../modules/03-storage/labs/cli-arm/02-lifecycle-policy.md) | [Portal](../modules/03-storage/labs/portal/02-lifecycle-policy.md)
3. [Azure Files Share + Mount (Conceptual + Optional VM) (CLI + ARM)](../modules/03-storage/labs/cli-arm/03-azure-files-share.md) | [Portal](../modules/03-storage/labs/portal/03-azure-files-share.md)
4. [SAS vs RBAC Access Test (CLI + ARM)](../modules/03-storage/labs/cli-arm/04-sas-vs-rbac.md) | [Portal](../modules/03-storage/labs/portal/04-sas-vs-rbac.md)

## Module 4 — Compute
### Lessons
1. [Virtual Machines Essentials](../modules/04-compute/lessons/01-virtual-machines.md)
2. [Availability: Sets and Zones](../modules/04-compute/lessons/02-availability-sets-zones.md)
3. [Scaling: VMSS and App Service](../modules/04-compute/lessons/03-scaling.md)
4. [App Service](../modules/04-compute/lessons/04-app-service.md)
5. [Containers: ACR + ACI + ACA Overview](../modules/04-compute/lessons/05-containers-acr-aci-aca.md)

### Labs
1. [Deploy a VM (Simple) (CLI + ARM)](../modules/04-compute/labs/cli-arm/01-deploy-vm.md) | [Portal](../modules/04-compute/labs/portal/01-deploy-vm.md)
2. [VM Availability (Set vs Zone) (CLI + ARM)](../modules/04-compute/labs/cli-arm/02-vm-availability.md) | [Portal](../modules/04-compute/labs/portal/02-vm-availability.md)
3. [VM Scale Set Autoscale (Basic) (CLI + ARM)](../modules/04-compute/labs/cli-arm/03-vmss-autoscale.md) | [Portal](../modules/04-compute/labs/portal/03-vmss-autoscale.md)
4. [Deploy App Service + Config (CLI + ARM)](../modules/04-compute/labs/cli-arm/04-app-service-deploy.md) | [Portal](../modules/04-compute/labs/portal/04-app-service-deploy.md)
5. [ACR Build + ACI Run Container (CLI + ARM)](../modules/04-compute/labs/cli-arm/05-acr-aci-container.md) | [Portal](../modules/04-compute/labs/portal/05-acr-aci-container.md)

## Module 5 — Monitoring, Backup & DR
### Lessons
1. [Azure Monitor Basics](../modules/05-monitoring/lessons/01-azure-monitor.md)
2. [Log Analytics + KQL](../modules/05-monitoring/lessons/02-log-analytics-kql.md)
3. [Alerts + Action Groups](../modules/05-monitoring/lessons/03-alerts-action-groups.md)
4. [Azure Backup](../modules/05-monitoring/lessons/04-azure-backup.md)
5. [Azure Site Recovery (ASR)](../modules/05-monitoring/lessons/05-azure-site-recovery.md)
6. [Availability & Resilience](../modules/05-monitoring/lessons/06-availability-resilience.md)

### Labs
1. [Enable VM Insights + Query Logs (CLI + ARM)](../modules/05-monitoring/labs/cli-arm/01-enable-vm-insights.md) | [Portal](../modules/05-monitoring/labs/portal/01-enable-vm-insights.md)
2. [Create an Alert + Action Group (CLI + ARM)](../modules/05-monitoring/labs/cli-arm/02-create-alert-action-group.md) | [Portal](../modules/05-monitoring/labs/portal/02-create-alert-action-group.md)
3. [Backup a VM + Restore Test (CLI + ARM)](../modules/05-monitoring/labs/cli-arm/03-backup-and-restore-vm.md) | [Portal](../modules/05-monitoring/labs/portal/03-backup-and-restore-vm.md)
4. [Service Health + Resource Health Alerts (CLI + ARM)](../modules/05-monitoring/labs/cli-arm/04-service-health-resource-health-alerts.md) | [Portal](../modules/05-monitoring/labs/portal/04-service-health-resource-health-alerts.md)
