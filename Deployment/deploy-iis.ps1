param(
    [Parameter(Mandatory=$true)]
    [string]$SiteName,

    [Parameter(Mandatory=$true)]
    [string]$BackendSource,

    [Parameter(Mandatory=$true)]
    [string]$FrontendSource
)

$ErrorActionPreference = "Stop"

$basePath = "F:\New_WWW\$SiteName"
$frontendPath = "$basePath\WWW"
$backendPath = "$basePath\API"
$appPoolName = $SiteName

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying $SiteName" -ForegroundColor Cyan
Write-Host "Frontend: $frontendPath" -ForegroundColor Gray
Write-Host "Backend:  $backendPath" -ForegroundColor Gray
Write-Host "App Pool: $appPoolName" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan

# Stop App Pool
Write-Host "`n>> Stopping App Pool: $appPoolName" -ForegroundColor Yellow
try {
    if ((Get-WebAppPoolState -Name $appPoolName).Value -eq "Started") {
        Stop-WebAppPool -Name $appPoolName
        Write-Host "   App pool stopped" -ForegroundColor Green
    } else {
        Write-Host "   App pool already stopped" -ForegroundColor Gray
    }
} catch {
    Write-Host "   Warning: Could not stop app pool - $_" -ForegroundColor Yellow
}

# Wait for pool to fully stop
Start-Sleep -Seconds 3

# Deploy Frontend
Write-Host "`n>> Deploying Frontend" -ForegroundColor Yellow
if (!(Test-Path $frontendPath)) {
    New-Item -ItemType Directory -Path $frontendPath -Force | Out-Null
}
Copy-Item -Path "$FrontendSource\*" -Destination $frontendPath -Recurse -Force
Write-Host "   Frontend deployed" -ForegroundColor Green

# Deploy Backend
Write-Host "`n>> Deploying Backend" -ForegroundColor Yellow
if (!(Test-Path $backendPath)) {
    New-Item -ItemType Directory -Path $backendPath -Force | Out-Null
}
Copy-Item -Path "$BackendSource\*" -Destination $backendPath -Recurse -Force
Write-Host "   Backend deployed" -ForegroundColor Green

# Start App Pool
Write-Host "`n>> Starting App Pool: $appPoolName" -ForegroundColor Yellow
try {
    Start-WebAppPool -Name $appPoolName
    Write-Host "   App pool started" -ForegroundColor Green
} catch {
    Write-Host "   Error starting app pool: $_" -ForegroundColor Red
    throw
}

# Health check
Write-Host "`n>> Running health check..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
try {
    $healthUrl = "http://localhost/$SiteName/api/health"
    $response = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 30
    if ($response.StatusCode -eq 200) {
        Write-Host "   Health check passed!" -ForegroundColor Green
    } else {
        Write-Host "   Health check returned: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Health check failed (non-critical): $_" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
