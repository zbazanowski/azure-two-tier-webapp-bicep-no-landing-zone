
# 📦 Step-by-Step: Create & Upload Azure Publish Profile to GitHub

This guide shows you how to securely configure your Azure Web App deployment using GitHub Actions and an Azure publish profile.

---

## 🔹 Step 1: Download the Publish Profile from Azure

1. Go to the [Azure Portal](https://portal.azure.com)
2. Navigate to your **Web App** (deployed from your Bicep template)
3. In the left-hand menu, select **"Deployment Center"** or **"Overview"**
4. Click the **"Get publish profile"** button  
5. Save the `.PublishSettings` file to your computer (e.g., `webappname.PublishSettings`)
6. Open the file in a text editor — **DO NOT commit this file to GitHub**

---

## 🔹 Step 2: Copy the Publish Profile Content

- Open the downloaded `.PublishSettings` file
- Copy the **entire XML content**
- You will paste this into GitHub as a secret

---

## 🔹 Step 3: Add the Secret to GitHub

1. Go to your GitHub repository
2. Click on **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Use the following:
   - **Name**: `AZURE_WEBAPP_PUBLISH_PROFILE`
   - **Value**: (paste the full XML content here)
5. Click **"Add secret"**

---

## 🔹 Step 4: (Optional) Add Your Web App Name as a Secret

To avoid hardcoding your web app name in the workflow, add:

- **Name**: `AZURE_WEBAPP_NAME`
- **Value**: the name of your deployed Web App (e.g., `contoso-dev-web`)

---

## 🔹 Step 5: Enable Deployment in Your GitHub Workflow

In `.github/workflows/nodejs-app-ci.yml`, uncomment the Azure deployment step:

```yaml
- name: Deploy to Azure Web App
  uses: azure/webapps-deploy@v2
  with:
    app-name: ${{ secrets.AZURE_WEBAPP_NAME }}
    slot-name: 'production'
    publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
    package: app/app.zip
```

---

## ✅ Done!

Now your CI pipeline will:
- Build and zip your Node.js app
- Upload it to Azure using the publish profile
