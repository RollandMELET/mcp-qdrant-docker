# Serveur MCP pour Qdrant

## Contexte du projet

Ce projet vise à créer un serveur MCP (Model Context Protocol) pour permettre à Claude d'accéder à une base de données vectorielle Qdrant déployée sur un VPS.

## État actuel du projet

- Le serveur Qdrant est déjà déployé et fonctionne correctement sur Coolify
  - URL: `http://qdrant-v8gc8cc4sk80o444ccck0gkg.178.16.129.71.sslip.io`
  - API Key: `obuONHxVHnSKivuN9Q5xqZGqtERfc2KM`
  - Collection: `ClaudeCollection`
- Le serveur MCP est en cours de déploiement mais rencontre des problèmes

## Problèmes rencontrés

1. Le serveur MCP ne démarre pas correctement dans le conteneur Docker
2. Le healthcheck échoue, ce qui empêche le déploiement complet sur Coolify
3. Nous avons tenté d'ajouter plus de logs et de déboguer le script de démarrage sans succès

## Structure du projet

- `Dockerfile`: Configuration du conteneur Docker pour le serveur MCP
- `docker-compose.yaml`: Configuration pour déployer le service via Coolify
- `start.sh`: Script de démarrage pour initialiser et lancer le serveur MCP

## Configuration requise

### Variables d'environnement

- `QDRANT_URL`: URL du serveur Qdrant
- `QDRANT_API_KEY`: Clé API pour l'authentification Qdrant
- `COLLECTION_NAME`: Nom de la collection Qdrant à utiliser

### Ports

- 8000: Port principal du serveur MCP
- 8001: Port utilisé pour le healthcheck

## Tentatives précédentes

1. Ajout du package `procps` pour résoudre le problème de la commande `ps` manquante
2. Modification du script start.sh pour ajouter plus de logs et des méthodes alternatives de démarrage
3. Correction de la taille des vecteurs de 1024 à 1536 pour Claude

## Solutions à explorer

1. Vérifier les logs complets du conteneur pour identifier la cause exacte de l'échec de démarrage
2. Tester le démarrage du serveur MCP localement avant le déploiement
3. Explorer les options de configuration de mcp-server-qdrant
4. Envisager d'utiliser une approche différente pour le healthcheck
5. Potentiellement explorer d'autres implémentations de serveur MCP pour Qdrant

## Documentation et ressources

- [Qdrant Documentation](https://qdrant.tech/documentation/)
- [MCP Protocol](https://github.com/anthropics/anthropic-cookbook/tree/main/mcp)
- [mcp-server-qdrant](https://github.com/qdrant/mcp-server-qdrant)

## Notes pour le débogage

Le script actuel tente de démarrer le serveur MCP avec la commande `python -m mcp_server_qdrant.main`. Il y a eu également une tentative avec `python -m mcp_server_qdrant.app`. 

Les logs du serveur sont consultables dans le conteneur à `/app/logs/mcp.log`.

## Prochaines étapes recommandées

1. Exécuter la commande pour récupérer les logs complets du conteneur
2. Analyser les dépendances exactes nécessaires pour mcp-server-qdrant
3. Tester manuellement le démarrage du serveur MCP dans un environnement isolé
4. Vérifier si la version actuelle du package est compatible avec le MCP utilisé par Claude
