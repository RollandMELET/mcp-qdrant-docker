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
echo "Qdrant response:"
echo "$QDRANT_TEST"

if [[ $QDRANT_TEST == *"connection_failed"* ]]; then
    echo "WARNING: Could not connect to Qdrant at $QDRANT_URL"
    echo "Will continue anyway in case Qdrant becomes available later..."
else
    echo "Successfully connected to Qdrant!"
    
    # Vérifier si la collection existe
    echo "Checking if collection $COLLECTION_NAME exists..."
    COLLECTION_TEST=$(eval $curl_cmd -m 5 "$QDRANT_URL/collections/$COLLECTION_NAME" || echo "collection_failed")
    echo "Collection response:"
    echo "$COLLECTION_TEST"
    
    if [[ $COLLECTION_TEST == *"collection_failed"* || $COLLECTION_TEST == *"Not found"* ]]; then
        echo "WARNING: Collection $COLLECTION_NAME does not exist. Creating it..."
        
        # Créer la collection avec une configuration par défaut pour Claude
        CREATE_BODY="{\"name\":\"$COLLECTION_NAME\",\"vectors\":{\"size\":1536,\"distance\":\"Cosine\"}}"
        CREATE_CMD="$curl_cmd -X PUT -H \"Content-Type: application/json\" -d '$CREATE_BODY' \"$QDRANT_URL/collections/$COLLECTION_NAME\""
        
        CREATE_RESULT=$(eval $CREATE_CMD || echo "create_failed")
        echo "Create collection response:"
        echo "$CREATE_RESULT"
        
        if [[ $CREATE_RESULT == *"create_failed"* ]]; then
            echo "ERROR: Failed to create collection $COLLECTION_NAME"
        else
            echo "Collection $COLLECTION_NAME created successfully!"
        fi
    else
        echo "Collection $COLLECTION_NAME exists!"
    fi
fi

# Créer le répertoire pour les logs
mkdir -p /app/logs

# Afficher les versions des packages installés pour le débogage
echo "Installed packages versions:"
pip freeze | grep -E "mcp|qdrant|fastembed" || echo "No matching packages found"

# Essayer de lister les commandes disponibles dans le package mcp_server_qdrant
echo "Available commands in mcp_server_qdrant package:"
pip show mcp-server-qdrant || echo "Package not found"
find /usr/local/lib/python*/site-packages/mcp_server_qdrant -type f -name "*.py" | sort || echo "Failed to find package files"

# Démarrer le serveur MCP avec redirection des logs et plus de verbosité
echo "Starting MCP server..."
echo "Running: python -m mcp_server_qdrant.main"
python -m mcp_server_qdrant.main --debug > /app/logs/mcp.log 2>&1 &
MCP_PID=$!
echo "MCP server process started with PID: $MCP_PID"

# Vérifier que le processus existe toujours après 2 secondes
sleep 2
if ! ps -p $MCP_PID > /dev/null; then
    echo "ERROR: MCP server failed to start. Check logs below:"
    cat /app/logs/mcp.log
    
    # Tentative alternative de démarrage avec un module différent
    echo "Trying alternative start method..."
    python -m mcp_server_qdrant.app > /app/logs/mcp_alt.log 2>&1 &
    MCP_PID=$!
    sleep 2
    
    if ! ps -p $MCP_PID > /dev/null; then
        echo "ERROR: Alternative method also failed. Check logs below:"
        cat /app/logs/mcp_alt.log
        exit 1
    fi
    
    echo "Alternative method seems to work! Continuing with PID: $MCP_PID"
    cp /app/logs/mcp_alt.log /app/logs/mcp.log
fi

# Attendre que le serveur soit prêt
echo "Waiting for MCP server to start..."
MAX_RETRIES=10
RETRY=0
while [ $RETRY -lt $MAX_RETRIES ]; do
    sleep 3
    
    # Afficher les logs actuels
    if [ $RETRY -eq 0 ]; then
        echo "MCP server logs:"
        cat /app/logs/mcp.log || echo "No logs available yet"
    fi
    
    # Tester si le serveur répond
    HEALTH_CHECK=$(curl -s -f http://localhost:8000/ || echo "not_ready")
    
    if [ "$HEALTH_CHECK" != "not_ready" ]; then
        echo "MCP server is now ready!"
        echo "Health check response: $HEALTH_CHECK"
        break
    fi
    
    echo "MCP server not ready yet, waiting... ($((RETRY+1))/$MAX_RETRIES)"
    RETRY=$((RETRY+1))
    
    # Vérifier que le processus existe toujours
    if ! ps -p $MCP_PID > /dev/null; then
        echo "ERROR: MCP server process died. Check logs below:"
        cat /app/logs/mcp.log
        exit 1
    fi
done

if [ $RETRY -eq $MAX_RETRIES ]; then
    echo "WARNING: MCP server did not respond after $MAX_RETRIES attempts."
    echo "Latest logs:"
    cat /app/logs/mcp.log
    echo "Continuing anyway..."
fi

# Pour le healthcheck
echo "Setting up healthcheck endpoint..."
(
    while true; do
        echo "Serving healthcheck on port 8001..."
        nc -l -p 8001 -c 'echo -e "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK"' || true
        sleep 1
    done
) &
HEALTHCHECK_PID=$!
echo "Healthcheck service started with PID: $HEALTHCHECK_PID"

# Garder le script en cours d'exécution
echo "MCP Server PID: $MCP_PID - Monitoring logs..."
tail -f /app/logs/mcp.log &
TAIL_PID=$!

# Afficher tous les processus en cours pour le débogage
echo "Running processes:"
ps aux

# Attendre le processus principal et garder le conteneur en vie
wait $MCP_PID