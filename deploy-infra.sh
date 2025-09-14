#!/usr/bin/env bash
# 01-without-lz/deploy-infra.sh
# Creates RG and deploys the Linux-based web + SQL infra.
set -euo pipefail

# load parameters
export DEPLOYMENT_PARAMS_CONFIG="deployment-params"
source ${DEPLOYMENT_PARAMS_CONFIG}

# print the parameters
cat ${DEPLOYMENT_PARAMS_CONFIG}
echo

echo "Creating resource group $RG in $LOCATION..."
az group create -n "$RG" -l "$LOCATION" >/dev/null


echo "Deploying infra (Linux App Service + SQL)..."
az deployment group create \
    --name "${DEPLOYMENT_NAME}" \
    -g "$RG" \
    -f main.bicep \
    -p \
        namePrefix="$PREFIX" env="$ENV" \
        location="$LOCATION" \
        sqlAdminPassword="$sqlPwd" \
        appServiceSku="$APPSKU" \
        clientIp="$CLIENT_IP" \
    --query "[ \
        {Name:'sqlServerFqdn',  Value: properties.outputs.sqlServerFqdn.value}, \
        {Name:'webUrl',         Value: properties.outputs.webUrl.value}, \
        {Name:'aspName',        Value: properties.outputs.aspName.value}, \
        {Name:'webName',        Value: properties.outputs.webName.value}, \
        {Name:'sqlServerName',  Value: properties.outputs.sqlServerName.value}, \
        {Name:'sqlDbName',      Value: properties.outputs.sqlDbName.value}, \
        {Name:'sqlAdminLogin',  Value: properties.outputs.sqlAdminLogin.value} \
    ]" \
    -o tsv

echo "Retrieve output variables"
output=$( \
    az deployment group show \
        --name "${DEPLOYMENT_NAME}" \
        -g "$RG" \
        --query "[ \
            {Name:'sqlServerFqdn',  Value: properties.outputs.sqlServerFqdn.value}, \
            {Name:'webUrl',         Value: properties.outputs.webUrl.value}, \
            {Name:'aspName',        Value: properties.outputs.aspName.value}, \
            {Name:'webName',        Value: properties.outputs.webName.value}, \
            {Name:'sqlServerName',  Value: properties.outputs.sqlServerName.value}, \
            {Name:'sqlDbName',      Value: properties.outputs.sqlDbName.value}, \
            {Name:'sqlAdminLogin',  Value: properties.outputs.sqlAdminLogin.value} \
        ]" \
        -o tsv | awk -F'\t' '{printf "export %s=\"%s\"\n",$1,$2}'
)

echo "Bicep output variables"
echo $output

# create environment variables
eval $output

source ../utils/util-functions.sh
save-variables sqlServerFqdn webUrl aspName webName sqlServerName sqlDbName sqlAdminLogin

# create db connection string

export SQL_CONNECTION_STRING="\
Server="${sqlServerFqdn}";\
Database="${sqlDbName}";\
User Id="${sqlAdminLogin}@${sqlServerName}";\
Password="${sqlPwd}";\
Encrypt=true;"

echo "DB connection string"
echo $SQL_CONNECTION_STRING


save-variables SQL_CONNECTION_STRING


echo "Saved parameters"
cat ${DEPLOYMENT_PARAMS_CONFIG}