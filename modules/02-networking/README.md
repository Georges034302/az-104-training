# Module 02 — Virtual Networking

> **Focus**: VNets, subnets, NSGs, peering, routing, DNS, and load balancing

This module covers Azure networking fundamentals, including virtual networks, security, connectivity, and traffic management.

## 📖 Lessons

1. **[VNet & Subnets](lessons/01-vnet-subnets.md)** - Virtual networks, address spaces, and subnet segmentation
2. **[VNet Peering](lessons/02-vnet-peering.md)** - Connect virtual networks with global and regional peering
3. **[Network Security Groups (NSG) & ASG](lessons/03-nsg-asg.md)** - Traffic filtering with security rules and application security groups
4. **[Routing & User-Defined Routes (UDR)](lessons/04-routing-udr.md)** - Custom route tables and network virtual appliances
5. **[Azure DNS](lessons/05-azure-dns.md)** - Public and private DNS zones for name resolution
6. **[Private Endpoints](lessons/06-private-endpoints.md)** - Secure PaaS services with private connectivity
7. **[Load Balancing](lessons/07-load-balancing.md)** - Azure Load Balancer, Application Gateway, and Traffic Manager

## 🧪 Labs

1. **[Create VNet, Subnets & NSG (CLI + ARM)](labs/cli-arm/01-create-vnet-subnets-nsg.md)** | **[Portal](labs/portal/01-create-vnet-subnets-nsg.md)** - Build a virtual network with security groups and traffic rules
2. **[VNet Peering Connectivity (CLI + ARM)](labs/cli-arm/02-vnet-peering-connectivity.md)** | **[Portal](labs/portal/02-vnet-peering-connectivity.md)** - Connect two VNets and verify cross-network communication
3. **[UDR Routing Simulation (CLI + ARM)](labs/cli-arm/03-udr-routing-simulation.md)** | **[Portal](labs/portal/03-udr-routing-simulation.md)** - Implement custom routes with route tables for traffic control
4. **[Private Endpoint for Storage with DNS (CLI + ARM)](labs/cli-arm/04-private-endpoint-storage-dns.md)** | **[Portal](labs/portal/04-private-endpoint-storage-dns.md)** - Secure blob storage with private endpoint and DNS integration
5. **[Basic Load Balancer (CLI + ARM)](labs/cli-arm/05-basic-load-balancer.md)** | **[Portal](labs/portal/05-basic-load-balancer.md)** - Deploy a public load balancer with backend pool and health probes

## Learning Outcomes

After completing this module, you will be able to:
- Design and implement virtual networks with proper segmentation
- Configure network security with NSGs and security rules
- Establish VNet connectivity using peering and custom routing
- Secure Azure services with private endpoints
- Implement load balancing for high availability
