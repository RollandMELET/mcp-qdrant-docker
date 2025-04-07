#!/bin/bash
set -e

echo "Starting MCP server with configuration:"
echo "QDRANT_URL: $QDRANT_URL"
echo "COLLECTION_NAME: $COLLECTION_NAME"
echo "API Key is configured: $([ -n "$QDRANT_API_KEY" ] && echo 'Yes' || echo 'No')"
echo "Embedding model: $EMBEDDING_MODEL"

# Créer un serveur simple pour le healthcheck
(
    while true; do
        { echo -e "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK"; } | nc -l -p 8000 || true
        echo "Health check pinged"
        sleep 1
    done
) &
HEALTHCHECK_PID=$!

# Démarrer le serveur MCP en mode mock si nécessaire
if [ "$MOCK_MODE" = "true" ]; then
    echo "Starting MCP server in MOCK MODE (no Qdrant connection required)..."
    # Juste garder le conteneur en vie pour que le healthcheck fonctionne
    tail -f /dev/null
else
    # Test de connexion à Qdrant (optionnel)
    if [ -n "$QDRANT_URL" ]; then
        echo "Testing connection to Qdrant at $QDRANT_URL..."
        curl_cmd="curl -s"
        if [ -n "$QDRANT_API_KEY" ]; then
            curl_cmd="$curl_cmd -H \"api-key:$QDRANT_API_KEY\""
        fi
        QDRANT_TEST=$(eval $curl_cmd -m 5 "$QDRANT_URL/collections" || echo "connection_failed")
        echo "Qdrant response:"
        echo "$QDRANT_TEST"
        
        if [[ $QDRANT_TEST == *"connection_failed"* ]]; then
            echo "WARNING: Could not connect to Qdrant at $QDRANT_URL"
            if [ "$IGNORE_CONNECTION_ERROR" != "true" ]; then
                echo "Set IGNORE_CONNECTION_ERROR=true to ignore this error."
                echo "Continuing anyway..."
            fi
        else
            echo "Successfully connected to Qdrant!"
        fi
    fi
    
    # Démarrer le serveur MCP
    echo "Starting MCP server..."
    exec python -m mcp_server_qdrant.server --transport sse
fi