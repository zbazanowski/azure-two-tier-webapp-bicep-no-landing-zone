
# 🔐 Securely Configure SQL Connection Strings for Azure Web Apps

This guide helps you securely pass your SQL connection string to the Web App — either via **App Settings**, or **Azure Key Vault reference**.

---

## ✅ Option 1: Set Connection String via App Settings (CLI or GitHub Secret)

### 🔹 Step 1: Create the connection string

Format:
```
Server=tcp:<sql-server-name>.database.windows.net,1433;Initial Catalog=<db-name>;User ID=<sql-admin>;Password=<sql-password>;Encrypt=True;Connection Timeout=30;
```

Example:
```
Server=tcp:contoso-dev-sql.database.windows.net,1433;Initial Catalog=messagesdb;User ID=sqladmin;Password=SuperSecurePwd123!;Encrypt=True;Connection Timeout=30;
```

---

### 🔹 Step 2: Set the connection string using Azure CLI

```bash
az webapp config connection-string set   --name <webapp-name>   --resource-group <resource-group>   --settings SqlDb="<your-connection-string>"   --connection-string-type SQLAzure
```

---

### 🔹 Or: Set via GitHub Actions Secret

1. Go to GitHub → **Settings** → **Secrets and variables** → **Actions**
2. Create a secret:
   - **Name**: `SQL_CONNECTION_STRING`
   - **Value**: (paste your connection string)
3. Use it in your workflow (via environment variable or `az` CLI)

---

## ✅ Option 2: Use Azure Key Vault Reference (Recommended for Production)

### 🔹 Step 1: Store secret in Key Vault

```bash
az keyvault secret set --vault-name <kv-name> --name SqlConnectionString --value "<your-connection-string>"
```

### 🔹 Step 2: Grant access to Web App's Managed Identity

```bash
az keyvault set-policy   --name <kv-name>   --object-id <webapp-msi-object-id>   --secret-permissions get list
```

You can get the identity object ID with:

```bash
az webapp identity show --name <webapp-name> --resource-group <rg-name> --query principalId
```

---

### 🔹 Step 3: Add a Key Vault reference to App Settings

Set an App Setting like:

```
@Microsoft.KeyVault(SecretUri=https://<kv-name>.vault.azure.net/secrets/SqlConnectionString/<version>)
```

Or omit version for auto-resolution:

```
@Microsoft.KeyVault(SecretUri=https://<kv-name>.vault.azure.net/secrets/SqlConnectionString/)
```

---

### 🔹 Step 4: Verify resolution in Portal

In Azure Portal → Web App → **Configuration**, you’ll see a green checkmark if the reference is working.

---

## ✅ Conclusion

- For **quick demos**, use direct CLI or GitHub Secrets.
- For **secure deployments**, use **Key Vault with Managed Identity** and **App Settings references**.
