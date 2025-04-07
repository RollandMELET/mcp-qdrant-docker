#!/bin/bash
echo "Starting MCP server with configuration:"
echo "QDRANT_URL: $QDRANT_URL"
echo "COLLECTION_NAME: $COLLECTION_NAME"
echo "API Key is configured: $([ -n "$QDRANT_API_KEY" ] && echo 'Yes' || echo 'No')"

# Vérifier que les variables d'environnement sont définies
if [ -z "$QDRANT_URL" ] || [ -z "$COLLECTION_NAME" ]; then
    echo "ERROR: Environment variables QDRANT_URL and COLLECTION_NAME must be set."
    exit 1
fi

# Attendre quelques secondes pour que les logs soient visibles
sleep 2

# Démarrer le serveur MCP
exec python -m mcp_server_qdrant.main