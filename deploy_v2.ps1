$ErrorActionPreference = "Stop"

# --- CONFIGURATION (NOUVEAU) ---
$RG_NAME = "wildfire-rg-v2"
$LOCATION = "norwayeast"
$SUFFIX = Get-Random -Minimum 1000 -Maximum 9999
$STORAGE_NAME = "wildfirestore$SUFFIX"
$FUNC_APP_NAME = "wildfire-func-$SUFFIX"
$WEB_APP_NAME = "wildfire-map-$SUFFIX"
$PLAN_NAME = "wildfire-plan-$SUFFIX"

Write-Host "--- 🚀 STARTING CLEAN DEPLOYMENT V2 ---" -ForegroundColor Cyan
Write-Host "Resource Group: $RG_NAME"
Write-Host "Storage: $STORAGE_NAME"
Write-Host "Web App: $WEB_APP_NAME"

# 1. Create Resource Group
Write-Host "`n[1/7] Creating Resource Group..." -ForegroundColor Yellow
az group create --name $RG_NAME --location $LOCATION

# 2. Create Storage Account & Container
Write-Host "`n[2/7] Creating Storage & Container..." -ForegroundColor Yellow
az storage account create --name $STORAGE_NAME --resource-group $RG_NAME --location $LOCATION --sku Standard_LRS --kind StorageV2 --allow-blob-public-access true

$ctx = az storage account show-connection-string -g $RG_NAME -n $STORAGE_NAME -o tsv
$env:AZURE_STORAGE_CONNECTION_STRING = $ctx

az storage container create --name data --public-access blob

# Upload Initial Data (Empty or Sample)
Write-Host "Uploading initial data..."
if (Test-Path "wildfires.json") {
    az storage blob upload --container-name data --name wildfires.json --file wildfires.json --overwrite
} else {
    Write-Host "[]" | Out-File initial.json
    az storage blob upload --container-name data --name wildfires.json --file initial.json --overwrite
    Remove-Item initial.json
}

# 3. Create & Deploy Function App
Write-Host "`n[3/7] Creating Function App (Python 3.10)..." -ForegroundColor Yellow
az functionapp create --resource-group $RG_NAME --consumption-plan-location $LOCATION --runtime python --runtime-version 3.10 --functions-version 4 --name $FUNC_APP_NAME --os-type linux --storage-account $STORAGE_NAME

Write-Host "Deploying Function Code..."
# Verify requirements
if (-not (Select-String -Path backend/requirements.txt -Pattern "azure-functions")) {
    Add-Content -Path backend/requirements.txt -Value "`nazure-functions`nrequests`nazure-storage-blob"
}

# Publish
cd backend
func azure functionapp publish $FUNC_APP_NAME --python
cd ..

# 4. Preparing Frontend
Write-Host "`n[4/7] Building Frontend (React)..." -ForegroundColor Yellow
$DATA_URL = "https://$STORAGE_NAME.blob.core.windows.net/data/wildfires.json"
Write-Host "Data URL: $DATA_URL"
$env:REACT_APP_DATA_URL = $DATA_URL

# Clean install
cmd /c "npm install"
# Build
cmd /c "npm run build"

if (-not (Test-Path "build\index.html")) {
    Write-Error "Build failed! index.html not found."
    exit 1
}

# 5. Create Web App (Static)
Write-Host "`n[5/7] Creating Web App (Node 18)..." -ForegroundColor Yellow
az appservice plan create --name $PLAN_NAME --resource-group $RG_NAME --sku F1 --is-linux
az webapp create --resource-group $RG_NAME --plan $PLAN_NAME --name $WEB_APP_NAME --runtime "NODE:18-lts"

# 6. Deploy Web App
Write-Host "`n[6/7] Deploying Web App..." -ForegroundColor Yellow
if (Test-Path "build.zip") { Remove-Item "build.zip" }
Compress-Archive -Path "build\*" -DestinationPath "build.zip" -Force

az webapp deployment source config-zip --resource-group $RG_NAME --name $WEB_APP_NAME --src build.zip

# Startup Command for React
az webapp config set --resource-group $RG_NAME --name $WEB_APP_NAME --startup-file "pm2 serve /home/site/wwwroot --no-daemon --spa"

# 7. Final Configuration (CORS)
Write-Host "`n[7/7] Configuring CORS..." -ForegroundColor Yellow
az storage cors add --methods GET HEAD --origins "*" --services b --allowed-headers "*" --exposed-headers "*" --max-age 3600 --account-name $STORAGE_NAME

# --- SUMMARY ---
Write-Host "`n--- ✅ DEPLOYMENT COMPLETE ---" -ForegroundColor Green
Write-Host "Frontend: https://$WEB_APP_NAME.azurewebsites.net"
Write-Host "Data API: $DATA_URL"
Write-Host "Function: https://$FUNC_APP_NAME.azurewebsites.net"
Write-Host "--------------------------------------------------"
