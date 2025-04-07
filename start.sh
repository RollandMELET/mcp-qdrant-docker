#!/bin/bash
set -e

echo "Starting MCP server with configuration:"
echo "QDRANT_URL: $QDRANT_URL"
echo "COLLECTION_NAME: $COLLECTION_NAME"
echo "API Key is configured: $([ -n "$QDRANT_API_KEY" ] && echo 'Yes' || echo 'No')"
echo "Embedding model: $EMBEDDING_MODEL"

# Vérifier que les variables d'environnement sont définies
if [ -z "$QDRANT_URL" ] || [ -z "$COLLECTION_NAME" ]; then
    echo "ERROR: Environment variables QDRANT_URL and COLLECTION_NAME must be set."
    exit 1
fi

# Tester la connexion à Qdrant
echo "Testing connection to Qdrant at $QDRANT_URL..."
curl_cmd="curl -s"
if [ -n "$QDRANT_API_KEY" ]; then
    curl_cmd="$curl_cmd -H \"api-key:$QDRANT_API_KEY\""
fi

# Tester la connexion avec un timeout
QDRANT_TEST=$(eval $curl_cmd -m 5 "$QDRANT_URL/collections" || echo "connection_failed")
echo "Qdrant response:"
echo "$QDRANT_TEST"

# Créer un serveur simple pour le healthcheck
(
    while true; do
        echo -e "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK" | nc -l -p 8000 || true
        echo "Health check pinged"
        sleep 1
    done
) &

# Démarrer le serveur MCP avec plus de verbosité
echo "Starting MCP server..."
python -m mcp_server_qdrant.server --transport sse --debug
