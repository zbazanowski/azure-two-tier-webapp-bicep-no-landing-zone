#!/usr/bin/env bash
# 01-without-lz/app/deploy-app.sh
# Builds and zip-deploys the Node app to the Linux Web App.
set -euo pipefail
RG="${1:-contoso-dev-rg}"
APP="${2:-contoso-dev-web}"

pushd "$(dirname "$0")" >/dev/null
npm install --omit=dev
zip -r app.zip . >/dev/null
echo "Deploying app.zip to $APP in $RG..."
az webapp deploy -g "$RG" -n "$APP" --src-path app.zip --type zip
echo "Open the site:"
az webapp browse -g "$RG" -n "$APP"
popd >/dev/null
