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

# Corriger l'URL si elle ne contient pas le domaine complet
if [[ $QDRANT_URL != *".sslip.io"* ]]; then
    echo "WARNING: QDRANT_URL doesn't contain full domain. Attempting to fix..."
    export QDRANT_URL="${QDRANT_URL}.178.16.129.71.sslip.io"
    echo "Updated QDRANT_URL: $QDRANT_URL"
fi

# Tester la connexion à Qdrant
echo "Testing connection to Qdrant at $QDRANT_URL..."
curl_cmd="curl -s"
if [ -n "$QDRANT_API_KEY" ]; then
    curl_cmd="$curl_cmd -H \"api-key:$QDRANT_API_KEY\""
fi

# Tester la connexion (avec un timeout)
QDRANT_TEST=$(eval $curl_cmd -m 5 "$QDRANT_URL/collections" || echo "connection_failed")
if [[ $QDRANT_TEST == *"connection_failed"* ]]; then
    echo "WARNING: Could not connect to Qdrant at $QDRANT_URL"
    echo "Will continue anyway in case Qdrant becomes available later..."
else
    echo "Successfully connected to Qdrant!"
fi

# Démarrer le serveur MCP
echo "Starting MCP server..."
python -m mcp_server_qdrant.main &
MCP_PID=$!

# Attendre que le serveur soit prêt
echo "Waiting for MCP server to start..."
MAX_RETRIES=10
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
    sleep 3
    if curl -s -f http://localhost:8000/ > /dev/null; then
        echo "MCP server is now ready!"
        break
    fi
    echo "MCP server not ready yet, waiting... ($((RETRY+1))/$MAX_RETRIES)"
    RETRY=$((RETRY+1))
done

# Garder le script en cours d'exécution
wait $MCP_PID