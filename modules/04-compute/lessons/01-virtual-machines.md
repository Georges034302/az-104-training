# Azure Virtual Machines Essentials (Deploy, Configure, Operate)

## Overview

Azure Virtual Machines provide infrastructure-as-a-service compute where you manage the guest OS, runtime, and application stack. In AZ-104, VM topics are core because they combine compute, networking, storage, identity, monitoring, and operational troubleshooting.

---

## What You Will Learn

- VM resource model and dependencies
- VM sizing and image selection principles
- OS disk and data disk planning basics
- Day-2 administration and troubleshooting workflow
- Security and operations practices expected in AZ-104 scenarios

---

## Architecture View

```
 [Admin/Automation]
        |
        v
 [Virtual Machine Resource]
     |         |         |
     v         v         v
 [NIC]     [OS/Data]  [Extensions]
   |         [Disks]      |
   v                      v
 [VNet/Subnet/NSG]   [Guest Configuration]
```

---

## Core Concepts

- **VM resource**: Control-plane object that defines size, image, and attached resources.
- **Image**: Source template for VM OS (publisher image or custom image).
- **Size**: Defines vCPU, memory, temporary storage profile, and max network/disk characteristics.
- **OS disk**: Boot/system disk for the VM.
- **Data disks**: Additional managed disks for application or data workloads.
- **NIC**: Connects VM to subnet, private IP, optional public IP.
- **NSG**: Filters traffic at subnet and/or NIC level.
- **Extensions**: Post-deploy configuration agents for tasks like scripting and monitoring bootstrap.
- **Provisioning state vs power state**: Provisioning state describes control-plane deployment status, while power state describes runtime state (for example running or deallocated).

Important: A VM deployment always creates or references several dependent resources, so troubleshooting often starts by checking dependencies, not only the VM object.

---

## VM Lifecycle and State Precision

- **Stopped (allocated)** can still incur compute charges.
- **Stopped (deallocated)** releases compute allocation and stops compute billing.
- **Restart** is a guest-level reboot path.
- **Redeploy** moves VM to a new host in-region to address host-level issues.

Operational implication: Incident triage and cost optimization decisions require checking both provisioning and power state, not one or the other.

---

## Sizing and Image Selection

When choosing a VM configuration, evaluate:

- workload CPU/memory profile
- disk throughput/IOPS requirements
- region and zone availability for the chosen SKU
- cost and scaling strategy

Practical guidance:

- use small SKUs for labs and admin jump hosts
- validate SKU availability in the target region before finalizing design
- avoid selecting by vCPU only; memory and disk/network limits matter too

---

## Disk and Storage Considerations

- Managed disks are the standard model in modern Azure VM designs.
- OS and data disk performance tiers affect workload behavior.
- Separate data from OS disk for maintainability and easier lifecycle operations.
- Snapshots and backup are separate protection mechanisms from redundancy settings.

Design implication: VM resilience planning is incomplete without explicit disk protection strategy.

---

## Identity, Access, and Security

- Prefer SSH keys (Linux) and controlled admin access methods over broad password exposure.
- Limit management ports (SSH/RDP) with restrictive NSG source rules.
- Use Microsoft Entra and RBAC for control-plane governance.
- Use managed identities for workload-to-service authentication when supported.
- Enable VM security posture features supported by the selected image/size (for example Trusted Launch in supported scenarios).

Operational baseline:

1. least-privilege RBAC for operators
2. restricted inbound management access
3. logging/monitoring enabled for change and health visibility

---

## Day-2 Operations You Must Know

- **Start/stop/deallocate**: Deallocate releases compute billing state.
- **Restart**: Guest OS restart without changing host placement intent.
- **Redeploy**: Moves VM to a new host within region to recover host-level issues.
- **Reapply**: Re-pushes platform state to the VM model when drift/troubleshooting requires it.
- **Reset password/SSH config**: Recovery actions when access fails.

Use boot diagnostics and serial console when network access is broken or guest boot is failing.

---

## Troubleshooting Workflow

1. Confirm VM power and provisioning state.
2. Confirm NIC/subnet/NSG effective configuration.
3. Validate route and DNS behavior for outbound dependency access.
4. Check disk attachment and extension provisioning status.
5. Use boot diagnostics and serial console for guest-level failure analysis.

This sequence prevents jumping to guest-level conclusions when the issue is actually network policy or platform placement.

---

## Common Pitfalls and Exam Traps

- Assuming VM delete always removes all dependent resources automatically.
- Opening SSH/RDP to all sources and treating it as acceptable baseline.
- Ignoring subnet NSG and route effects while troubleshooting VM connectivity.
- Choosing VM size without checking region/zone availability.
- Confusing VM stop with deallocate when reasoning about cost.
- Troubleshooting runtime access issues without checking whether provisioning state actually failed.
- Assuming security hardening is complete with NSGs alone while ignoring identity and guest-level controls.

---

## Quick CLI Reference

```bash
# Create VM (example)
az vm create \
  --resource-group <rg> \
  --name <vm-name> \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username <admin-user> \
  --generate-ssh-keys

# Show VM power state
az vm get-instance-view \
  --resource-group <rg> \
  --name <vm-name> \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" \
  -o tsv

# Deallocate VM
az vm deallocate --resource-group <rg> --name <vm-name>

# Redeploy VM
az vm redeploy --resource-group <rg> --name <vm-name>
```

---

## Further Reading

- https://learn.microsoft.com/en-us/azure/virtual-machines/overview
- https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/overview
- https://learn.microsoft.com/en-us/azure/virtual-machines/extensions/overview
