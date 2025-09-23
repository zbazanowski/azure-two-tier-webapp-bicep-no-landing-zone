# Minimal Web App (Linux) for Azure App Service + Azure SQL

Endpoints:
- `/` — welcome text
- `/health` — heartbeat
- `/db/ping` — SELECT 1
- `/db/init` — create table + insert row
- `/db/messages` — list rows

## Deploy app (zip deploy)
```bash
./deploy-app.sh contoso-dev-rg contoso-dev-web
```
