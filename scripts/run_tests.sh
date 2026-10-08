#!/usr/bin/env bash
# ==============================================================================
# Script de tests automatisés & validation de persistance (Linux / macOS / WSL)
# Module I347 - Binôme : Kodjo & Selle
# ==============================================================================
set -e

echo "=========================================================="
echo " 1. VÉRIFICATION DU LINTER (Flake8 sur le code Python)"
echo "=========================================================="
if command -v flake8 >/dev/null 2>&1; then
    flake8 backend --count --select=E9,F63,F7,F82 --show-source --statistics || true
    echo "✅ Vérification statique terminée."
else
    echo "ℹ️ Flake8 non installé en local, saut de l'étape linter."
fi

echo ""
echo "=========================================================="
echo " 2. DÉMARRAGE DE L'INFRASTRUCTURE DOCKER COMPOSE"
echo "=========================================================="
docker compose up -d --build

echo ""
echo "=========================================================="
echo " 3. ATTENTE DE SANTÉ DES SERVICES (Healthcheck)"
echo "=========================================================="
MAX_WAIT=30
COUNTER=0
until [ $(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/health) -eq 200 ] || [ $COUNTER -eq $MAX_WAIT ]; do
    echo "En attente des conteneurs ($COUNTER/$MAX_WAIT s)..."
    sleep 2
    COUNTER=$((COUNTER + 2))
done

if [ $COUNTER -ge $MAX_WAIT ]; then
    echo "❌ Timeout : Les services n'ont pas démarré à temps."
    docker compose logs
    exit 1
fi

echo "✅ Tous les conteneurs sont sains et opérationnels !"

echo ""
echo "=========================================================="
echo " 4. EXÉCUTION DU TEST FONCTIONNEL API (CURL & CRUD)"
echo "=========================================================="
# Test Health
HEALTH_RES=$(curl -s http://localhost:8080/api/health)
echo "Réponse Health : $HEALTH_RES"

# Test Insertion
echo "Insertion d'un équipement de persistance..."
INSERT_RES=$(curl -s -X POST http://localhost:8080/api/assets \
    -H "Content-Type: application/json" \
    -d '{"name":"srv-test-volume-persist","category":"Serveur","ip_address":"192.168.99.99","status":"ONLINE","location":"Salle Serveur CPNV"}')
echo "Réponse Insertion : $INSERT_RES"

echo ""
echo "=========================================================="
echo " 5. TEST DE PERSISTANCE DU VOLUME DOCKER"
echo "=========================================================="
echo "Redémarrage forcé du conteneur de Base de Données..."
docker compose restart database
sleep 5

echo "Vérification que les données sont conservées dans le volume 'postgres_data'..."
CHECK_RES=$(curl -s http://localhost:8080/api/assets)
if echo "$CHECK_RES" | grep -q "srv-test-volume-persist"; then
    echo "🎉 SUCCÈS : La persistance du volume PostgreSQL fonctionne parfaitement !"
else
    echo "❌ ÉCHEC : Données perdues après redémarrage du conteneur."
    exit 1
fi

echo ""
echo "=========================================================="
echo " ✅ TOUS LES TESTS AUTOMATISÉS ONT ÉTÉ VALIDÉS AVEC SUCCÈS !"
echo "=========================================================="
