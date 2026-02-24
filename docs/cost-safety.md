# Cost + Safety Guardrails

## Rules
- Always deploy to a dedicated Resource Group per lab.
- Always run cleanup at the end.
- Prefer free/low-cost SKUs where possible.
- Avoid leaving public IPs running longer than needed.

## High-cost areas to watch
- VPN Gateway / ExpressRoute (not used here)
- Application Gateway (kept optional / basic)
- Azure Site Recovery (can be cost/time intensive; lesson is included, lab is lightweight and optional)
- VM sizes: prefer `Standard_B1s` (where available)

## Default region
- `australiaeast`
