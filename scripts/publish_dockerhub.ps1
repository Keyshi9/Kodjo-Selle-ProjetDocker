# ==============================================================================
# Script de Publication sur Docker Hub (Conformité Sujet n°10 - Windows)
# Module I347 - Binôme : Kodjo & Selle
# ==============================================================================
param (
    [string]$DockerHubUser = "keyshi9"
)

$ImageName = "i347-flask-inventory-api"
$VersionTag = "1.0.0"

$FullTagVersion = "$DockerHubUser/$ImageName`:$VersionTag"
$FullTagLatest = "$DockerHubUser/$ImageName`:latest"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " SUJET 10 : PUBLICATION D'UNE IMAGE SUR DOCKER HUB" -ForegroundColor Cyan
Write-Host " Utilisateur cible : $DockerHubUser" -ForegroundColor Yellow
Write-Host " Image : $ImageName" -ForegroundColor Yellow
Write-Host "=========================================================="

Write-Host "`n📦 1. Construction de l'image Docker multi-stage..." -ForegroundColor Cyan
docker build -t $FullTagVersion -t $FullTagLatest ./backend

Write-Host "`n🔑 2. Connexion à Docker Hub..." -ForegroundColor Cyan
Write-Host "Veuillez entrer vos identifiants Docker Hub si demandé :"
docker login

Write-Host "`n🚀 3. Push des images vers Docker Hub..." -ForegroundColor Cyan
docker push $FullTagVersion
docker push $FullTagLatest

Write-Host "`n🧪 4. Test du Pull depuis Docker Hub..." -ForegroundColor Cyan
Write-Host "Suppression temporaire du tag local pour tester le pull..."
docker rmi $FullTagVersion -f
docker pull $FullTagVersion

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host " 🎉 PUBLICATION ET VALIDATION RÉUSSIES SUR DOCKER HUB !" -ForegroundColor Green
Write-Host " URL : https://hub.docker.com/r/$DockerHubUser/$ImageName" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Green
