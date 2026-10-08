# ==============================================================================
# Dockerfile Multi-Stage Optimisé et Sécurisé
# Module I347 - Virtualisation d'une application avec conteneurs
# Binôme : Kodjo & Selle
# ==============================================================================

# ------------------------------------------------------------------------------
# Étape 1 : Build & Dépendances (Builder Stage)
# ------------------------------------------------------------------------------
FROM python:3.11-slim AS builder

WORKDIR /build

# Dépendances système requises pour la compilation de packages C/Postgres
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Création d'un environnement virtuel isolé
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt


# ------------------------------------------------------------------------------
# Étape 2 : Image d'Exécution Minimale & Sécurisée (Runtime Stage)
# ------------------------------------------------------------------------------
FROM python:3.11-slim AS runner

# Métadonnées OCI
LABEL maintainer="Kodjo & Selle - CPNV"
LABEL description="API Flask CloudAsset Manager multi-stage non-root"
LABEL version="1.0.0"

WORKDIR /app

# Dépendances runtime minimales (libpq5 pour postgres, curl pour le HEALTHCHECK)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Sécurité : Création d'un utilisateur non-root dédié (UID/GID 10001)
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -s /bin/sh -d /app -m appuser

# Copie de l'environnement virtuel Python depuis l'étape builder
COPY --from=builder --chown=appuser:appgroup /opt/venv /opt/venv

# Copie des fichiers applicatifs avec attribution des droits à l'utilisateur non-root
COPY --chown=appuser:appgroup app.py config.py ./

# Configuration de l'environnement
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    FLASK_ENV=production

# Passage à l'utilisateur non-root pour réduire la surface d'attaque
USER appuser

# Port interne de l'application
EXPOSE 5000

# Vérification d'état (Healthcheck Docker natif)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:5000/api/health || exit 1

# Démarrage avec le serveur WSGI de production Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "30", "--access-logfile", "-", "app:app"]
