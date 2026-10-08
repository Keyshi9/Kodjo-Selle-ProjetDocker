import os
import socket
import time
import psycopg2
from psycopg2.extras import RealDictCursor
from flask import Flask, jsonify, request
from flask_cors import CORS
from config import Config

app = Flask(__name__)
CORS(app)

def get_db_connection(max_retries=5, delay=2):
    """Établit la connexion à la base de données avec mécanisme de réessai."""
    retry = 0
    while retry < max_retries:
        try:
            conn = psycopg2.connect(
                host=Config.POSTGRES_HOST,
                port=Config.POSTGRES_PORT,
                dbname=Config.POSTGRES_DB,
                user=Config.POSTGRES_USER,
                password=Config.POSTGRES_PASSWORD,
                cursor_factory=RealDictCursor,
                connect_timeout=3
            )
            return conn
        except psycopg2.OperationalError as err:
            retry += 1
            if retry >= max_retries:
                raise err
            time.sleep(delay)

@app.route("/", methods=["GET"])
def index():
    return jsonify({
        "status": "online",
        "service": Config.APP_NAME,
        "version": Config.APP_VERSION,
        "hostname": socket.gethostname(),
        "endpoints": [
            "/api/health",
            "/api/info",
            "/api/assets",
            "/api/stats"
        ]
    })

@app.route("/api/health", methods=["GET"])
def healthcheck():
    """Healthcheck endpoint pour Docker et le monitoring."""
    db_ok = False
    db_error = None
    try:
        conn = get_db_connection(max_retries=1, delay=0)
        with conn.cursor() as cur:
            cur.execute("SELECT 1;")
            cur.fetchone()
        conn.close()
        db_ok = True
    except Exception as e:
        db_error = str(e)

    status_code = 200 if db_ok else 503
    return jsonify({
        "status": "healthy" if db_ok else "unhealthy",
        "container_hostname": socket.gethostname(),
        "database_connected": db_ok,
        "database_host": Config.POSTGRES_HOST,
        "database_error": db_error,
        "timestamp": time.time()
    }), status_code

@app.route("/api/info", methods=["GET"])
def get_info():
    """Retourne les métadonnées de l'architecture conteneurisée."""
    return jsonify({
        "application": Config.APP_NAME,
        "version": Config.APP_VERSION,
        "environment": Config.FLASK_ENV,
        "container_id": socket.gethostname(),
        "database_target": f"{Config.POSTGRES_HOST}:{Config.POSTGRES_PORT}/{Config.POSTGRES_DB}",
        "docker_network": "backend-network (internal isolated)"
    })

@app.route("/api/assets", methods=["GET"])
def get_assets():
    """Récupère la liste des équipements dans la BDD."""
    try:
        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, category, ip_address, status, location, created_at FROM assets ORDER BY id ASC;")
            rows = cur.fetchall()
        conn.close()
        return jsonify({
            "success": True,
            "count": len(rows),
            "data": rows
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/api/assets", methods=["POST"])
def create_asset():
    """Ajoute un nouvel équipement dans la base de données."""
    payload = request.get_json(silent=True) or {}
    name = payload.get("name", "").strip()
    category = payload.get("category", "").strip()
    ip_address = payload.get("ip_address", "").strip()
    status = payload.get("status", "ONLINE").strip().upper()
    location = payload.get("location", "Datacenter Lausanne").strip()

    if not name or not category or not ip_address:
        return jsonify({
            "success": False,
            "error": "Les champs 'name', 'category' et 'ip_address' sont obligatoires."
        }), 400

    if status not in ["ONLINE", "OFFLINE", "MAINTENANCE"]:
        status = "ONLINE"

    try:
        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO assets (name, category, ip_address, status, location)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id, name, category, ip_address, status, location, created_at;
                """,
                (name, category, ip_address, status, location)
            )
            new_item = cur.fetchone()
            conn.commit()
        conn.close()
        return jsonify({"success": True, "data": new_item}), 201
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/api/assets/<int:asset_id>", methods=["DELETE"])
def delete_asset(asset_id):
    """Supprime un équipement par son ID."""
    try:
        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute("DELETE FROM assets WHERE id = %s RETURNING id;", (asset_id,))
            deleted = cur.fetchone()
            conn.commit()
        conn.close()

        if not deleted:
            return jsonify({"success": False, "error": f"Équipement #{asset_id} introuvable."}), 404

        return jsonify({"success": True, "message": f"Équipement #{asset_id} supprimé avec succès."})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route("/api/stats", methods=["GET"])
def get_stats():
    """Calcule des statistiques globales sur le parc."""
    try:
        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) AS total FROM assets;")
            total = cur.fetchone()["total"]
            cur.execute("SELECT status, COUNT(*) AS count FROM assets GROUP BY status;")
            by_status = {row["status"]: row["count"] for row in cur.fetchall()}
        conn.close()
        return jsonify({
            "success": True,
            "total_assets": total,
            "status_breakdown": {
                "ONLINE": by_status.get("ONLINE", 0),
                "OFFLINE": by_status.get("OFFLINE", 0),
                "MAINTENANCE": by_status.get("MAINTENANCE", 0)
            }
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=Config.FLASK_PORT, debug=False)
