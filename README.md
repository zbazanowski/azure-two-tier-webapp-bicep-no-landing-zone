
# azure-two-tier-webapp-bicep-no-landing-zone

This project demonstrates a **minimal two-tier application architecture** on Azure, using **Bicep** to deploy a **Linux Web App (Node.js)** and an **Azure SQL Database**, **without Landing Zone guardrails**.

It serves as a baseline to contrast with more secure, governed deployments using Landing Zones.

---

## 📌 Project Highlights

- **No Landing Zone guardrails**: Public access to SQL, no private DNS, no NSG rules
- **Bicep-based deployment**: Fully declarative infrastructure as code
- **Two-tier architecture**: 
  - Node.js App Service (Linux)
  - Azure SQL Database (Basic tier)
- **Parameterization** for easy environment reuse
- **Shell scripts** for automation (`deploy`, `sanity check`, `set params`)
- **Extensible**: Forms the baseline for a future LZ-compliant variant

---

## 📐 Architecture Overview

```text
+-------------------+      Public Access     +-----------------------+
|                   |  ------------------->  |                       |
|   Linux Web App   |                        | Azure SQL Database    |
| (Node.js backend) | <-------------------   |  (Basic tier, public) |
|                   |     SQL Connection     |                       |
+-------------------+                        +-----------------------+

Deployment Type: Bicep
Infrastructure Scope: Resource Group
```

---

## 🚀 Deployment Steps

### 1. 🧬 Clone the Repository

```bash
git clone https://github.com/your-org/azure-two-tier-webapp-bicep-no-landing-zone.git
cd azure-two-tier-webapp-bicep-no-landing-zone/01-without-lz
```

### 2. 🛠️ Set Parameters

Customize and export deployment parameters:

```bash
./set-params.sh contoso dev westeurope "" "" <your-public-ip> without-lz
```

This sets:
- Resource group name
- Environment name
- Location
- App SKU
- SQL admin password (generated)
- Client IP for SQL firewall
- Deployment name

### 3.  🏗️ Provision Infrastructure

```bash
./deploy-infra.sh
```

This will:
- Create the resource group
- Deploy the App Service Plan, Web App, SQL Server, and Database
- Output key deployment information (e.g., Web App URL, SQL FQDNs, resource names)

### 4. 🚀 Deploy the Node.js App

```bash
cd app
./deploy-app.sh <resource-group-name> <web-app-name>
```

Example:
```bash
cd app
./deploy-app.sh contoso-dev-rg contoso-dev-web
```

This script will:
- Run npm install --omit=dev
- Package the app into app.zip
- Deploy it to the Web App using az webapp deploy --type zip
- Open the app in your browser

### 5. 🔑 Set the DB connection string in the Web App

Use the respective command in:
```bash
./sanity-check.sh
```

### 6. 🔥 Create a firewall rule for the SQL server

Create a firewall rule for connections from any Azure service or asset to the SQL server.

Use the respective command in:
```bash
./sanity-check.sh
```

---

## 🧪 Sanity Checks

After deployment, you can verify the environment with:

```bash
./sanity-check.sh
```

This runs a series of checks:
- List resources
- Show deployment outputs
- Inspect web app settings
- Test connectivity to SQL (coming soon)

---

## 🧰 Technologies Used

- **Azure Resource Manager (ARM)**
- **Bicep**
- **Azure CLI**
- **Linux App Service (Node.js)**
- **Azure SQL Database (Basic tier)**
- **Bash scripting**

---

## ⚠️ Limitations (on purpose)

This deployment **does not** include:
- Private endpoints or VNet integration
- DNS or name resolution across network boundaries
- Azure Policies or RBAC guardrails
- Key Vault integration
- Managed identity

The purpose is to show what a **barebones, ungoverned deployment** looks like — to later compare it against a secure, Landing Zone-based setup.

---

## 📂 Project Structure

```text
01-without-lz/
├── main.bicep             # Bicep template for all infra
├── deploy-infra.sh        # Script to deploy infra
├── set-params.sh          # Script to define deployment parameters
├── sanity-check.sh        # Script to validate deployment
├── deployment-params      # Parameter source loaded by scripts
├── deployed-template.json # Deployment result (optional)
├── app/
│   ├── server.js          # Minimal Node.js app
│   ├── package.json
│   ├── deploy-app.sh      # Placeholder to deploy app to Web App
│   └── app.zip            # Pre-packaged app bundle
```

---

## 🔜 Next Steps (Optional)

- Extend this baseline into `02-with-lz` using:
  - Private endpoints
  - Key Vault references
  - Centralized DNS
  - Role-based access controls

---

## 👤 Author

Zbynek Bazanowski (Baz), Solution Architect  
GitHub: [zbazanowski](https://github.com/zbazanowski)

https://chatgpt.com/share/68a2fc91-6958-800a-a802-eb98fa508165

---

## 📄 License

MIT License. See `LICENSE` file.
