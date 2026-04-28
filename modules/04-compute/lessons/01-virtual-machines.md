# Azure Virtual Machines: Deployment, Operations, and Troubleshooting

> Azure Virtual Machines (VMs) provide **infrastructure-as-a-service compute** where you manage the guest operating system, patching, software stack, security posture, and operational lifecycle.

---

## Overview

VMs remain one of the most important AZ-104 topics because they connect several Azure administration areas together:

- compute sizing and cost control
- networking and secure remote access
- managed disks and storage performance
- backup, monitoring, and patching
- RBAC, identities, and troubleshooting

An Azure VM is never truly “just one resource.” A working design includes the VM plus its NIC, subnet, NSG, disks, identity model, and operational tooling.

---

## What You Will Learn

- The Azure VM resource model and key dependencies
- How to choose the right VM image and size
- OS disk, data disk, and storage planning basics
- Secure access and day-2 administrative operations
- Common troubleshooting workflows, examples, and exam traps

## Acronyms and Terms (Do Not Assume)

- IaaS = Infrastructure as a Service
- PaaS = Platform as a Service
- SKU = Stock Keeping Unit (Azure size/tier identifier)
- vCPU = virtual Central Processing Unit
- RAM = Random Access Memory
- IOPS = Input/Output Operations Per Second
- NSG = Network Security Group
- NIC = Network Interface Card
- SLA = Service Level Agreement

These terms are used throughout Azure compute operations and decision-making.

---

## VM Mental Model

```text
[Admin / Automation / Portal / CLI]
              |
              v
      [Virtual Machine resource]
         |        |         |
         v        v         v
      [NIC]   [OS disk] [Extensions]
         |        |
         v        v
 [VNet / Subnet / NSG]   [Data disks / Backup / Snapshots]
```

---

## When to Choose a VM

Use an Azure VM when you need:

- full OS-level control
- custom software installation or legacy app support
- administrator access to the guest OS
- workloads that do not fit a PaaS hosting model like App Service

Avoid VMs when a managed platform can reduce operational overhead significantly.

## Deep Dive: Azure Compute Model Comparison

Choosing a VM should be a deliberate architectural decision, not a default habit.

| Compute model | You manage | Azure manages | Best fit |
|---|---|---|---|
| Virtual Machines (IaaS) | OS, patching, middleware, runtime, app | Datacenter, host, hypervisor | Legacy apps, custom OS control, deep system access |
| App Service (PaaS) | App code, config, identity, deployments | OS/runtime patching, platform ops | Web apps and APIs with lower ops overhead |
| Containers on ACI/ACA | Container image and app | Host and platform runtime | Portable app packaging, modern deployment patterns |

Professional guidance:
- Use VMs when you need operating-system-level control.
- Use PaaS/container platforms when you want faster delivery and reduced maintenance burden.
- Many enterprise environments use a mix of all three models.

## VM Lifecycle Responsibilities (What Admins Must Own)

For VM-based workloads, administrators are responsible for:

1. Patch strategy (OS and middleware)
2. Hardening baseline (accounts, ports, endpoint protection)
3. Backup and restore testing
4. Monitoring and alerting
5. Capacity and cost management

This ownership model is the primary trade-off for VM flexibility.

---

## Core Components of a VM

| Component | Purpose | Notes |
|---|---|---|
| **VM resource** | Main compute definition | Size, image, availability settings |
| **Image** | OS source | Marketplace, custom image, or Azure Compute Gallery |
| **Size / SKU** | CPU, memory, network, disk profile | Example: `Standard_B2s`, `D-series`, `E-series` |
| **NIC** | Network connectivity | Private IP, subnet, NSG interaction |
| **OS disk** | Boot disk | Required for the operating system |
| **Data disks** | Additional storage | App data, logs, DB files, shared workload separation |
| **Extensions** | Post-deployment configuration | Monitoring agents, scripts, security tooling |
| **Managed identity** | App/service authentication | Avoids storing credentials in the VM |

---

## Provisioning State vs Power State

This distinction appears frequently in AZ-104 questions.

- **Provisioning state** = whether the Azure deployment action succeeded
- **Power state** = whether the VM is running, stopped, or deallocated

### Important billing point

| State | Meaning | Billing impact |
|---|---|---|
| **Running** | VM is active | Compute billed |
| **Stopped (allocated)** | Guest OS is off, host still reserved | Compute can still be billed |
| **Stopped (deallocated)** | VM is released from the host | Compute billing stops |

> **Stopped** is not the same as **deallocated**. This is one of the most common AZ-104 exam traps.

---

## Choosing a VM Size

When choosing a VM size, do not focus only on vCPU count.

### Evaluate:

- CPU and memory requirements
- disk throughput and IOPS needs
- number of supported NICs and data disks
- region or zone availability for the SKU
- expected growth and cost boundary

### Simple workload guidance

| Workload type | Common pattern |
|---|---|
| Lab VM / jump box | Smaller `B-series` or entry-level general purpose |
| General app server | `D-series` general-purpose instance |
| Memory-heavy app | `E-series` memory-optimized instance |
| Batch / interruption-tolerant workload | Consider **Spot VMs** if eviction risk is acceptable |

Always validate SKU availability in the target region before standardizing.

---

## Image Selection

Azure VMs can be deployed from:

- **Marketplace images** such as Ubuntu, Windows Server, SQL-enabled images
- **Custom images** captured from a prepared source VM
- **Azure Compute Gallery images** for enterprise image standardization and version control

Good image selection affects:

- security baseline
- patching approach
- licensing cost
- extension compatibility
- deployment consistency across environments

---

## Disk and Storage Planning

### OS disk
The OS disk contains system files and is required for boot.

### Data disks
Use data disks for:

- application data
- logs
- databases
- anything that should survive OS rebuilds more cleanly

### Practical guidance

- keep app data off the OS disk when possible
- choose the right disk performance tier for the workload
- use managed disks for simpler, production-ready operations

This separation improves backup, maintenance, and recovery workflows.

---

## Networking and Secure Access

A professional VM design usually includes:

- subnet placement in the correct VNet segment
- NSG rules with least privilege
- restricted or no public IP exposure
- **Azure Bastion** or tightly scoped source IP rules for admin access
- private DNS or outbound access design where the workload depends on internal services

### Better admin access pattern

Instead of exposing SSH or RDP to the full internet:

- use **Azure Bastion**
- allow only trusted IP ranges
- use **SSH keys** for Linux
- combine with just-in-time or tightly scoped admin access

---

## Day-2 VM Operations You Must Know

| Operation | Meaning |
|---|---|
| **Start** | Power on the VM |
| **Stop** | Guest OS stop; may still remain allocated |
| **Deallocate** | Stops the VM and releases compute allocation |
| **Restart** | Reboots the guest OS |
| **Resize** | Changes the VM size if supported/capacity is available |
| **Redeploy** | Moves the VM to a new Azure host |
| **Reapply** | Re-applies Azure platform/model configuration |
| **Reset credentials** | Recovery option for admin password or SSH issues |

For access failures, **boot diagnostics**, **serial console**, and **Run Command** are valuable troubleshooting tools.

---

## Monitoring, Backup, and Continuity

For production VMs, plan more than just deployment:

- enable diagnostic visibility and Azure Monitor integration
- configure Azure Backup for recoverability
- track guest health, disk pressure, and extension failures
- document restart, redeploy, and restore procedures

A VM without monitoring and backup is only partially managed.

---

## Example Scenarios

### 1. Internal Linux admin tool

Good design:

- `Standard_B2s` or similar low-cost VM
- private subnet with restricted NSG
- SSH key access only
- Azure Backup and monitoring enabled

### 2. Legacy line-of-business application

Good design:

- marketplace or custom Windows image
- separate data disks for app and logs
- availability design if uptime matters
- least-privilege admin access and patching process

### 3. Poor design example

- public IP with `0.0.0.0/0` RDP or SSH access
- all workload data on the OS disk
- no monitoring, no backup, and no recovery plan

---

## CLI Reference

### Create a Linux VM

```bash
az vm create \
  --resource-group <rg> \
  --name vm01 \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureadmin \
  --generate-ssh-keys
```

### Show the VM power state

```bash
az vm get-instance-view \
  --resource-group <rg> \
  --name vm01 \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" \
  -o tsv
```

### Deallocate a VM

```bash
az vm deallocate \
  --resource-group <rg> \
  --name vm01
```

### Redeploy a VM to a new host

```bash
az vm redeploy \
  --resource-group <rg> \
  --name vm01
```

---

## Troubleshooting Checklist

If a VM is unavailable or inaccessible:

1. Check **provisioning state** and **power state** first.
2. Verify the NIC, subnet, NSG, and effective routes.
3. Confirm DNS and outbound dependency access.
4. Review disk health and extension state.
5. Use boot diagnostics, serial console, or Run Command for guest-level issues.

This sequence helps isolate **platform**, **network**, and **guest OS** problems in the right order.

---

## Common Pitfalls

- Confusing **stop** with **deallocate**.
- Assuming deleting a VM removes every dependent resource automatically.
- Exposing SSH or RDP broadly to the internet.
- Troubleshooting guest access before checking NSGs, routes, or provisioning status.
- Choosing a size without validating regional or zonal availability.

---

## Key Takeaways

- An Azure VM is part of a larger design involving **networking, storage, identity, and operations**.
- Good administration requires understanding **lifecycle state**, **cost state**, and **recovery options**.
- Secure access, monitoring, backup, and disciplined day-2 operations are essential to production VM management.

---

## Advanced: VM Operations and Lifecycle Governance

### Image and Patch Strategy

- Use curated golden images for baseline consistency
- Define patch cadence by workload criticality
- Validate rollback strategy for failed updates

### Access and Hardening

- Prefer Just-In-Time access and Bastion over open management ports
- Apply endpoint protection, vulnerability scanning, and baseline policies
- Separate admin access paths from application traffic

### Capacity and Cost Controls

- Right-size continuously using utilization and performance metrics
- Use reservations/savings plans where predictable
- Deallocate non-production VMs outside business windows

## Extended Troubleshooting Matrix (Virtual Machines)

| Symptom | Likely cause | Validation step | Fix |
|--------|--------------|----------------|-----|
| VM not reachable | NSG, routing, or guest firewall block | Test effective rules and boot diagnostics | Correct network path and guest firewall |
| High CPU or memory pressure | Undersized VM or workload spike | Review metrics and process utilization | Resize VM or optimize workload |
| Extension provisioning failure | Dependency or permission issue | Inspect extension logs and status | Reapply extension with corrected prerequisites |
| Disk performance bottleneck | Inadequate disk tier/caching configuration | Check IOPS/throughput metrics | Upgrade disk tier and tune caching |

## Production Readiness Checklist (Virtual Machines)

- Golden image, patching, and vulnerability process defined
- Access hardened with JIT/Bastion and least privilege
- Backup and recovery tested for critical VMs
- Monitoring and alerting configured for key VM signals
- Capacity and cost optimization cadence established
- Operational runbooks documented for common incidents


---

## Further Reading

- [Azure Virtual Machines overview](https://learn.microsoft.com/en-us/azure/virtual-machines/overview)
- [Virtual machine sizes in Azure](https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/overview)
- [Virtual machine extensions overview](https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/overview)
- [Boot diagnostics for Azure VMs](https://learn.microsoft.com/en-us/azure/virtual-machines/boot-diagnostics)
