#!/usr/bin/env bash
# ==============================================================================
# Script de Publication sur Docker Hub (Conformité Sujet n°10)
# Module I347 - Binôme : Kodjo & Selle
# ==============================================================================
set -e

# Configuration
DOCKERHUB_USER=${1:-"keyshi9"}
IMAGE_NAME="i347-flask-inventory-api"
VERSION_TAG="1.0.0"

FULL_TAG_VERSION="$DOCKERHUB_USER/$IMAGE_NAME:$VERSION_TAG"
FULL_TAG_LATEST="$DOCKERHUB_USER/$IMAGE_NAME:latest"

echo "=========================================================="
echo " SUJET 10 : PUBLICATION D'UNE IMAGE SUR DOCKER HUB"
echo " Utilisateur cible : $DOCKERHUB_USER"
echo " Image : $IMAGE_NAME"
echo "=========================================================="

echo ""
echo "📦 1. Construction de l'image Docker multi-stage..."
docker build -t "$FULL_TAG_VERSION" -t "$FULL_TAG_LATEST" ./backend

echo ""
echo "🔑 2. Connexion à Docker Hub..."
echo "Veuillez vous authentifier sur Docker Hub si ce n'est pas déjà fait :"
docker login

echo ""
echo "🚀 3. Push des images vers Docker Hub..."
docker push "$FULL_TAG_VERSION"
docker push "$FULL_TAG_LATEST"

echo ""
echo "🧪 4. Test du Pull depuis Docker Hub..."
echo "Suppression de l'image locale pour simuler une nouvelle machine..."
docker rmi "$FULL_TAG_VERSION" || true
echo "Téléchargement de l'image depuis Docker Hub :"
docker pull "$FULL_TAG_VERSION"

echo ""
echo "=========================================================="
echo " 🎉 PUBLICATION ET VALIDATION RÉUSSIES SUR DOCKER HUB !"
echo " URL : https://hub.docker.com/r/$DOCKERHUB_USER/$IMAGE_NAME"
echo "=========================================================="
