FROM python:3.11-slim

WORKDIR /app

# Installer curl et netcat pour le healthcheck et le débogage
RUN apt-get update && apt-get install -y curl netcat-traditional && rm -rf /var/lib/apt/lists/*

# Installer les dépendances nécessaires
RUN pip install --no-cache-dir mcp-server-qdrant

# Variables d'environnement
ENV QDRANT_URL=""
ENV QDRANT_API_KEY=""
ENV COLLECTION_NAME=""
ENV EMBEDDING_MODEL="sentence-transformers/all-MiniLM-L6-v2"
ENV IGNORE_CONNECTION_ERROR="false"
ENV MOCK_MODE="false"

# Copier le script de démarrage
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Expose port
EXPOSE 8000

# Un healthcheck simple qui vérifie si le serveur est en cours d'exécution
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8000/ || exit 1

# Démarrer le serveur MCP
CMD ["/app/start.sh"]