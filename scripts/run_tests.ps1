# ==============================================================================
# Script de tests automatisés & validation de persistance (Windows PowerShell)
# Module I347 - Binôme : Kodjo & Selle
# ==============================================================================

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " 1. DÉMARRAGE DE L'INFRASTRUCTURE DOCKER COMPOSE" -ForegroundColor Cyan
Write-Host "=========================================================="
docker compose up -d --build

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " 2. ATTENTE DE SANTÉ DES SERVICES (Healthcheck)" -ForegroundColor Cyan
Write-Host "=========================================================="
$maxWait = 30
$counter = 0
$healthy = $false

while ($counter -lt $maxWait) {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/health" -Method Get -TimeoutSec 2 -ErrorAction Stop
        if ($response.status -eq "healthy" -and $response.database_connected -eq $true) {
            $healthy = $true
            break
        }
    } catch {
        # En attente
    }
    Write-Host "En attente des conteneurs ($counter/$maxWait s)..."
    Start-Sleep -Seconds 2
    $counter += 2
}

if (-not $healthy) {
    Write-Host "❌ Timeout : Les services n'ont pas répondu à temps." -ForegroundColor Red
    docker compose logs
    exit 1
}

Write-Host "✅ Tous les conteneurs sont sains et opérationnels !" -ForegroundColor Green

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " 3. TEST FONCTIONNEL API (Insertion)" -ForegroundColor Cyan
Write-Host "=========================================================="
$body = @{
    name = "srv-test-volume-persist"
    category = "Serveur"
    ip_address = "192.168.99.99"
    status = "ONLINE"
    location = "Salle Serveur CPNV"
} | ConvertTo-Json

$insertRes = Invoke-RestMethod -Uri "http://localhost:8080/api/assets" -Method Post -Body $body -ContentType "application/json"
Write-Host "Équipement inséré avec succès (ID: $($insertRes.data.id))" -ForegroundColor Green

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " 4. TEST DE PERSISTANCE DU VOLUME DOCKER" -ForegroundColor Cyan
Write-Host "=========================================================="
Write-Host "Redémarrage du conteneur de Base de Données..."
docker compose restart database
Start-Sleep -Seconds 5

$assets = Invoke-RestMethod -Uri "http://localhost:8080/api/assets" -Method Get
$found = $assets.data | Where-Object { $_.name -eq "srv-test-volume-persist" }

if ($found) {
    Write-Host "🎉 SUCCÈS : La persistance du volume PostgreSQL fonctionne parfaitement !" -ForegroundColor Green
    # Nettoyage
    Invoke-RestMethod -Uri "http://localhost:8080/api/assets/$($found.id)" -Method Delete | Out-Null
    Write-Host "Donnée temporaire de test nettoyée." -ForegroundColor Gray
} else {
    Write-Host "❌ ÉCHEC : Données perdues après redémarrage du conteneur." -ForegroundColor Red
    exit 1
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host " ✅ TOUS LES TESTS AUTOMATISÉS ONT ÉTÉ VALIDÉS AVEC SUCCÈS !" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
