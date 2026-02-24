# Routing and UDR (Controlling Next Hop)

## What you will learn
- System routes vs UDR
- When to use route tables
- How to validate effective routes

## Concept flow architecture
```mermaid
flowchart LR
  Subnet[Subnet] --> RT[Route Table (UDR)]
  RT --> NextHop[Next hop: Internet/NVA/VNet/Peering]
  NextHop --> Dest[Destination]
```

## Key concepts (AZ-104 focus)
- System routes are created automatically; UDR lets you override next hop selection.
- UDR commonly used for forced tunneling or steering traffic via firewall/NVA.
- Validation uses effective routes on NIC or route table associations.

## Admin mindset
- Keep route tables simple; document why each route exists.
- Validate with effective routes and network watcher connectivity checks.
- Be careful with default route 0.0.0.0/0; it can break access.

## Common pitfalls / exam traps
- Associating route table to wrong subnet.
- Creating conflicting routes with different priorities/longest prefix wins confusion.
- Forgetting required egress for OS updates when forcing routing.

## Quick CLI signals (read-only examples)
> These are **signals** you look for as an administrator. They are not a full lab.
```bash
# az <service> <command> ... 
```
