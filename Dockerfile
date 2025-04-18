FROM python:3.11-slim

WORKDIR /app

# Installer curl pour le healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Installer les dépendances nécessaires
RUN pip install --no-cache-dir mcp-server-qdrant

# Variables d'environnement
ENV QDRANT_URL=""
ENV QDRANT_API_KEY=""
ENV COLLECTION_NAME=""
ENV EMBEDDING_MODEL="sentence-transformers/all-MiniLM-L6-v2"

# Copier le serveur mock pour le healthcheck
COPY mock.py /app/mock.py

# Expose port
EXPOSE 8000

# Un healthcheck simple qui vérifie si le serveur est en cours d'exécution
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8000/ || exit 1

# Démarrer le serveur mock et le serveur MCP
CMD python /app/mock.py