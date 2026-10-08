import os

class Config:
    POSTGRES_USER = os.getenv("POSTGRES_USER", "appuser")
    POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "secure_postgres_pass_2026")
    POSTGRES_DB = os.getenv("POSTGRES_DB", "inventory_db")
    POSTGRES_HOST = os.getenv("POSTGRES_HOST", "database")
    POSTGRES_PORT = int(os.getenv("POSTGRES_PORT", 5432))
    
    FLASK_PORT = int(os.getenv("FLASK_PORT", 5000))
    FLASK_ENV = os.getenv("FLASK_ENV", "production")
    APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
    APP_NAME = os.getenv("APP_NAME", "CloudAsset Manager")
