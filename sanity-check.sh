#!/usr/bin/env bash
set -euo pipefail

source ../utils/util-functions.sh


# load parameters
# load parameters
export DEPLOYMENT_PARAMS_CONFIG="deployment-params"
source ${DEPLOYMENT_PARAMS_CONFIG}

titles=()
commands=()

split <<'EOF'
# List all deployed resources
az resource list --resource-group "${RG}" --output table

# Show all deployments in the resource group (deployment history)
az deployment group list --resource-group "${RG}" --output table

# Retrieve output variables from the deployment
az deployment group show --resource-group "${RG}" --name "${DEPLOYMENT_NAME}" --query "properties.outputs"

# Retrieve output variables from the deployment -o tsv
az deployment group show --resource-group "${RG}" --name "${DEPLOYMENT_NAME}" \
    --query "[ 
        {Name:'sqlServerFqdn',  Value: properties.outputs.sqlServerFqdn.value}, \
        {Name:'webUrl',         Value: properties.outputs.webUrl.value}, \
        {Name:'aspName',        Value: properties.outputs.aspName.value}, \
        {Name:'webName',        Value: properties.outputs.webName.value}, \
        {Name:'sqlServerName',  Value: properties.outputs.sqlServerName.value}, \
        {Name:'sqlDbName',      Value: properties.outputs.sqlDbName.value}, \
        {Name:'sqlAdminLogin',  Value: properties.outputs.sqlAdminLogin.value} \
    ]" \
    -o tsv


# App Service Plan check
az appservice plan show --name "${aspName}" --resource-group "${RG}" --output table

# Web App check
az webapp show --name "${webName}" --resource-group "${RG}" --output json

# SQL Server check
az sql server show --name "${sqlServerName}" --resource-group "${RG}"

# SQL firewall rules
az sql server firewall-rule list  --server "${sqlServerName}" --resource-group "${RG}"

# SQL DB check
az sql db show --name "${sqlDbName}" --server "${sqlServerName}" --resource-group "${RG}"

# Check in browser
az webapp browse --name "${webName}" --resource-group "${RG}"

# What-if deployment (non-destructive preview)
az deployment group what-if \
    -g "$RG" \
    --template-file main.bicep \
    -p \
        namePrefix="$PREFIX" env="$ENV" \
        location="$LOCATION" \
        sqlAdminPassword="$sqlPwd" \
        appServiceSku="$APPSKU" \
        clientIp="$CLIENT_IP"

# Find the outbound IPs of the Web App
az webapp show \
  --name "${webName}" \
  --resource-group "${RG}" \
  --query outboundIpAddresses \
  --output tsv

# Restart the Web App
az webapp restart \
  --name "${webName}" \
  --resource-group "${RG}" \

# List the Settings of the Web App
az webapp config appsettings list \
  --name "${webName}" \
  --resource-group "${RG}"

# Set the DB connection string in the Web App
az webapp config appsettings set \
  --name "${webName}" \
  --resource-group "${RG}" \
  --settings \
    DefaultConnection="${SQL_CONNECTION_STRING}"

# Validate the Bicep template without comparing against deployed infra
az deployment group validate \
    -g "$RG" \
    --template-file main.bicep \
    -p \
        namePrefix="$PREFIX" env="$ENV" \
        location="$LOCATION" \
        sqlAdminPassword="$sqlPwd" \
        appServiceSku="$APPSKU" \
        clientIp="$CLIENT_IP"

# Export deployed template from Azure (reverse lookup)
az deployment group show \
  --name "${DEPLOYMENT_NAME}" \
  --resource-group "$RG" \
  --query properties.template \
  --output json > deployed-template.json

# Exit
exit
EOF


# Main menu loop
while true; do
  clear
  echo "===== Command Menu ====="
  for i in "${!titles[@]}"; do
    printf "%2d) %s\n" $((i + 1)) "${titles[$i]}"
  done
  echo
  read -p "Choose an option (1-${#titles[@]}): " choice

  # Validate input
  if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#titles[@]} )); then
    index=$((choice - 1))
    clear
    echo "# ${titles[$index]}"
    echo "---"
    echo -n "\$ ${commands[$index]}"
    echo "---"
    eval echo "\$ ${commands[$index]}"
    echo "========================="
    eval "${commands[$index]}"
    echo "-------------------------"
    read -p "Press Enter to return to menu ... "
  else
    echo "Invalid option. Please enter a number between 1 and ${#titles[@]}."
    sleep 2
  fi
done