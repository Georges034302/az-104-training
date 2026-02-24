# Module 02 — Virtual Networking

> **Focus**: VNets, subnets, NSGs, peering, routing, DNS, and load balancing

This module covers Azure networking fundamentals, including virtual networks, security, connectivity, and traffic management.

## 📖 Lessons

- **[VNet & Subnets](lessons/vnet-subnets.md)** - Virtual networks, address spaces, and subnet segmentation
- **[VNet Peering](lessons/vnet-peering.md)** - Connect virtual networks with global and regional peering
- **[Network Security Groups (NSG) & ASG](lessons/nsg-asg.md)** - Traffic filtering with security rules and application security groups
- **[Routing & User-Defined Routes (UDR)](lessons/routing-udr.md)** - Custom route tables and network virtual appliances
- **[Azure DNS](lessons/azure-dns.md)** - Public and private DNS zones for name resolution
- **[Private Endpoints](lessons/private-endpoints.md)** - Secure PaaS services with private connectivity
- **[Load Balancing](lessons/load-balancing.md)** - Azure Load Balancer, Application Gateway, and Traffic Manager

## 🧪 Labs

- **[Create VNet, Subnets & NSG](labs/create-vnet-subnets-nsg.md)** - Build a virtual network with security groups and traffic rules
- **[VNet Peering Connectivity](labs/vnet-peering-connectivity.md)** - Connect two VNets and verify cross-network communication
- **[UDR Routing Simulation](labs/udr-routing-simulation.md)** - Implement custom routes with route tables for traffic control
- **[Private Endpoint for Storage with DNS](labs/private-endpoint-storage-dns.md)** - Secure blob storage with private endpoint and DNS integration
- **[Basic Load Balancer](labs/basic-load-balancer.md)** - Deploy a public load balancer with backend pool and health probes

## Learning Outcomes

After completing this module, you will be able to:
- Design and implement virtual networks with proper segmentation
- Configure network security with NSGs and security rules
- Establish VNet connectivity using peering and custom routing
- Secure Azure services with private endpoints
- Implement load balancing for high availability
