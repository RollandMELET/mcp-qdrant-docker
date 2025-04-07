## Serveur MCP pour Qdrant

## Contexte du projet

Ce projet fournit un serveur MCP (Model Context Protocol) pour permettre à Claude d'accéder à une base de données vectorielle Qdrant déployée sur un VPS.

## Configuration

* Le serveur Qdrant est déployé sur Coolify
  + URL: `http://qdrant-v8gc8cc4sk80o444ccck0gkg.178.16.129.71.sslip.io`
  + Collection: `ClaudeCollection`
* Le serveur MCP est déployé via Docker pour exposer le serveur Qdrant à Claude

## Structure du projet

* `Dockerfile`: Configuration du conteneur Docker pour le serveur MCP
* `docker-compose.yaml`: Configuration pour déployer le service via Coolify

## Configuration requise

### Variables d'environnement

* `QDRANT_URL`: URL du serveur Qdrant
* `QDRANT_API_KEY`: Clé API pour l'authentification Qdrant
* `COLLECTION_NAME`: Nom de la collection Qdrant à utiliser
* `EMBEDDING_MODEL`: Modèle d'embedding à utiliser (par défaut: sentence-transformers/all-MiniLM-L6-v2)

### Ports

* 8000: Port principal du serveur MCP (avec support SSE pour connexion à distance)

## Utilisation avec Claude Desktop

Pour configurer Claude Desktop afin qu'il utilise ce serveur MCP, modifiez le fichier `claude_desktop_config.json` comme suit:

```json
{
  "mcpServers": {
    "qdrant": {
      "url": "http://votre-adresse-ip:8000/sse",
      "transport": "sse"
    }
  }
}
```

Remplacez `votre-adresse-ip` par l'adresse IP publique de votre VPS ou le domaine complet fourni par Coolify.

## Documentation et ressources

* [Qdrant Documentation](https://qdrant.tech/documentation/)
* [MCP Protocol](https://modelcontextprotocol.io/)
* [mcp-server-qdrant](https://github.com/qdrant/mcp-server-qdrant)