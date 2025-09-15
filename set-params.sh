#!/usr/bin/env bash

set -euo pipefail

PREFIX="${1:-contoso}"
ENV="${2:-dev}"
LOCATION="${3:-westeurope}"
RG="${4:-$PREFIX-$ENV-rg}"
APPSKU="${5:-B1}"
CLIENT_IP="${6:-}"   # optional: x.x.x.x to allow your IP on SQL firewall
DEPLOYMENT_NAME="${7:-deployment-without-lz}" 

# ./set-params.sh contoso dev westeurope "" "" 178.17.3.8 without-lz 

# Generate a random strong password for SQL admin
sqlPwd="$(python3 - <<'PY'
import random
chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%^&*()-_=+'
print(''.join(random.choice(chars) for _ in range(40)))
PY
)"

# save additional parameter
export DEPLOYMENT_PARAMS_CONFIG="deployment-params"
source utils/util-functions.sh

save-variables \
PREFIX \
ENV \
LOCATION \
RG \
APPSKU \
CLIENT_IP \
DEPLOYMENT_NAME \
sqlPwd
