#!/usr/bin/env python3
"""
Suite de tests automatisés d'intégration et de fonctionnement de l'API.
Module I347 - Binôme : Kodjo & Selle
"""
import sys
import time
import requests

BASE_URL = "http://localhost:8080/api"

def log_test(name, success, detail=""):
    badge = "✅ [PASS]" if success else "❌ [FAIL]"
    print(f"{badge} {name} {f'({detail})' if detail else ''}")
    return success

def wait_for_api(timeout=45):
    print(f"Attente de la disponibilité de l'API sur {BASE_URL}/health ...")
    start = time.time()
    while time.time() - start < timeout:
        try:
            res = requests.get(f"{BASE_URL}/health", timeout=3)
            if res.status_code == 200 and res.json().get("status") == "healthy":
                print("API et Base de Données prêtes et saines !")
                return True
        except Exception:
            pass
        time.sleep(2)
    return False

def run_all_tests():
    all_passed = True
    print("\n========================================================")
    print(" Lancement de la suite de tests automatisés (Module I347)")
    print("========================================================\n")

    if not wait_for_api():
        print("❌ L'API n'a pas répondu à temps.")
        return False

    # Test 1 : Healthcheck
    try:
        res = requests.get(f"{BASE_URL}/health", timeout=5)
        data = res.json()
        t1 = (res.status_code == 200 and data.get("status") == "healthy" and data.get("database_connected") is True)
        all_passed &= log_test("1. Test Healthcheck & Connexion PostgreSQL", t1)
    except Exception as e:
        all_passed &= log_test("1. Test Healthcheck", False, str(e))

    # Test 2 : Info & Métadonnées
    try:
        res = requests.get(f"{BASE_URL}/info", timeout=5)
        data = res.json()
        t2 = (res.status_code == 200 and "version" in data and "container_id" in data)
        all_passed &= log_test("2. Test Endpoint Info & Architecture", t2, f"Conteneur: {data.get('container_id')}")
    except Exception as e:
        all_passed &= log_test("2. Test Endpoint Info", False, str(e))

    # Test 3 : Liste des Assets (GET initial)
    try:
        res = requests.get(f"{BASE_URL}/assets", timeout=5)
        data = res.json()
        t3 = (res.status_code == 200 and data.get("success") is True and len(data.get("data", [])) > 0)
        all_passed &= log_test("3. Test Récupération des Équipements (Seed SQL)", t3, f"{len(data.get('data', []))} trouvés")
    except Exception as e:
        all_passed &= log_test("3. Test Récupération Assets", False, str(e))

    # Test 4 : Création d'un Asset (POST)
    created_id = None
    try:
        payload = {
            "name": "srv-test-ci-automated",
            "category": "Conteneur Docker",
            "ip_address": "10.0.0.99",
            "status": "ONLINE",
            "location": "Datacenter Test"
        }
        res = requests.post(f"{BASE_URL}/assets", json=payload, timeout=5)
        data = res.json()
        t4 = (res.status_code == 201 and data.get("success") is True)
        if t4:
            created_id = data["data"]["id"]
        all_passed &= log_test("4. Test Insertion d'un Nouvel Équipement", t4, f"ID créé: {created_id}")
    except Exception as e:
        all_passed &= log_test("4. Test Insertion Asset", False, str(e))

    # Test 5 : Statistiques globales (GET /api/stats)
    try:
        res = requests.get(f"{BASE_URL}/stats", timeout=5)
        data = res.json()
        t5 = (res.status_code == 200 and data.get("success") is True and data.get("total_assets", 0) >= 1)
        all_passed &= log_test("5. Test Endpoint Statistiques", t5, f"Total: {data.get('total_assets')}")
    except Exception as e:
        all_passed &= log_test("5. Test Endpoint Stats", False, str(e))

    # Test 6 : Suppression de l'Asset de test (DELETE)
    if created_id:
        try:
            res = requests.delete(f"{BASE_URL}/assets/{created_id}", timeout=5)
            data = res.json()
            t6 = (res.status_code == 200 and data.get("success") is True)
            all_passed &= log_test("6. Test Suppression de l'Équipement de test", t6)
        except Exception as e:
            all_passed &= log_test("6. Test Suppression Asset", False, str(e))

    print("\n--------------------------------------------------------")
    if all_passed:
        print("🎉 TOUS LES TESTS FONCTIONNELS ONT RÉUSSI AVEC SUCCÈS !")
    else:
        print("⚠️ CERTAINS TESTS ONT ÉCHOUÉ.")
    print("--------------------------------------------------------\n")

    return all_passed

if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
