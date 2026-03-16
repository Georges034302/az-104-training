# Module 01 — Identity & Governance

> **Focus**: Azure AD (Entra ID), RBAC, managed identities, and governance controls

This module covers the fundamentals of identity and access management in Azure, including authentication, authorization, and resource governance.


## 📖 Lessons

1. **[Entra ID Basics](lessons/01-entra-id-basics.md)** - Azure Active Directory fundamentals, users, groups, and authentication methods
2. **[Role-Based Access Control (RBAC)](lessons/02-rbac.md)** - Permission management with built-in and custom roles at different scopes
3. **[Managed Identities](lessons/03-managed-identities.md)** - System and user-assigned identities for secure service-to-service authentication
4. **[Azure Policy](lessons/04-azure-policy.md)** - Policy definitions, compliance evaluation, and enforcement for governance
5. **[Resource Management: Locks & Tags](lessons/05-resource-management-locks-tags.md)** - Resource protection with locks and organization with tags

---

## Lab & Diagram Standards

- **All labs use parameterized variables and `.env` files** for easy reuse and automation.
- **Explicit cleanup steps** are included in every lab (e.g., `az group delete`, `rm -f .env`).
- **Portal labs are step-by-step and precise**—not just high-level summaries.
- **All diagrams are text-based** (no Mermaid diagrams).

## 🧪 Labs

1. **[RBAC Role Assignment (CLI + ARM)](labs/cli-arm/01-rbac-role-assignment.md)** | **[Portal](labs/portal/01-rbac-role-assignment.md)** - Assign Azure roles to users and service principals with different permission levels
2. **[Managed Identity Storage Access (CLI + ARM)](labs/cli-arm/02-managed-identity-storage-access.md)** | **[Portal](labs/portal/02-managed-identity-storage-access.md)** - Configure managed identity to access Azure Storage without credentials
3. **[Tags, Locks & Policy (CLI + ARM)](labs/cli-arm/03-tags-lock-policy.md)** | **[Portal](labs/portal/03-tags-lock-policy.md)** - Apply resource tags, deletion locks, and Azure Policy for governance
4. **[Entra Users, Groups & Group-Based RBAC (CLI + ARM)](labs/cli-arm/04-entra-users-groups-rbac.md)** | **[Portal](labs/portal/04-entra-users-groups-rbac.md)** - Create Entra users/groups and assign RBAC through group membership

## Learning Outcomes

After completing this module, you will be able to:
- Configure Azure AD users, groups, and authentication
- Implement role-based access control across subscriptions and resource groups
- Use managed identities for secure service authentication
- Apply governance controls with tags, locks, and policies
