# Module 04 — Compute Resources

> **Focus**: VM operations, availability design, scaling strategy, App Service administration, and container runtimes

This module covers the Azure compute topics most relevant to AZ-104: virtual machine lifecycle operations, availability design choices, autoscaling patterns, App Service operational management, and container deployment on Azure.

## 📖 Lessons

1. **[Virtual Machines](lessons/01-virtual-machines.md)** - VM resource model, lifecycle states, dependency troubleshooting, and secure operations
2. **[Availability Sets & Zones](lessons/02-availability-sets-zones.md)** - Availability set versus zonal architecture and resilience trade-offs
3. **[Scaling](lessons/03-scaling.md)** - Scale up/down versus out/in, VMSS autoscale policy design, and App Service plan scaling semantics
4. **[App Service](lessons/04-app-service.md)** - Plan tiers, app configuration, deployment slots, and networking behavior
5. **[Containers: ACR, ACI & ACA](lessons/05-containers-acr-aci-aca.md)** - Image registry workflows, runtime selection, and secure image pull patterns

## 🧪 Labs

1. **[Deploy a Virtual Machine (CLI + ARM)](labs/cli-arm/01-deploy-vm.md)** | **[Portal](labs/portal/01-deploy-vm.md)** - Deploy Linux VM with subnet-level NSG control and runtime/network validation
2. **[VM Availability (CLI + ARM)](labs/cli-arm/02-vm-availability.md)** | **[Portal](labs/portal/02-vm-availability.md)** - Deploy two VMs in one availability set and validate domain-aware placement
3. **[VMSS Autoscale (CLI + ARM)](labs/cli-arm/03-vmss-autoscale.md)** | **[Portal](labs/portal/03-vmss-autoscale.md)** - Configure bounded CPU-based autoscale policies for VM Scale Sets
4. **[App Service Deploy (CLI + ARM)](labs/cli-arm/04-app-service-deploy.md)** | **[Portal](labs/portal/04-app-service-deploy.md)** - Create App Service plan + web app and verify configuration/runtime endpoint behavior
5. **[ACR & ACI Container (CLI + ARM)](labs/cli-arm/05-acr-aci-container.md)** | **[Portal](labs/portal/05-acr-aci-container.md)** - Build in ACR and deploy to ACI with private image pull validation

## Lab Standards

- **CLI + ARM track**: Fully parameterized with `.env`, explicit validation, and cleanup.
- **Portal track**: Detailed step-by-step procedures aligned with equivalent CLI outcomes.
- **Architecture diagrams**: Text-only boxes/arrows (no Mermaid).
- **Safety**: Every lab uses dedicated resource groups and includes cleanup commands.

## Learning Outcomes

After completing this module, you will be able to:
- Deploy and operate Azure virtual machines with secure and observable practices
- Choose and implement appropriate availability designs for compute workloads
- Configure and validate autoscaling behavior for VMSS and App Service plans
- Manage App Service configuration and deployment workflows safely
- Build, store, and run container images on Azure compute runtimes
