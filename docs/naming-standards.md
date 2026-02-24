# Naming Standards

## Default variables used in labs
- `LOCATION="australiaeast"`
- `PREFIX="az104"`
- `LAB="<module>-<topic>"` (e.g., `m02-vnet`)
- `RG_NAME="${PREFIX}-${LAB}-rg"`

## Resource naming guidance (simple + unique)
Because storage/ACR names must be globally unique, labs use a random suffix:
- `SUFFIX="$(openssl rand -hex 3)"` (or any 6-char random string)
- `NAME="${PREFIX}${LAB//-/}${SUFFIX}"` (letters/numbers only)

## Tagging
Recommended tags (optional):
- `course=az104`
- `module=<01..05>`
- `lab=<lab-id>`
