FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir uvicorn
RUN pip install --no-cache-dir fastembed
RUN pip install --no-cache-dir qdrant-client
RUN pip install --no-cache-dir mcp-server-qdrant

ENV QDRANT_URL=""
ENV QDRANT_API_KEY=""
ENV COLLECTION_NAME=""

# Expose the port the server runs on
EXPOSE 8000

# Health check to ensure the container is running properly
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/healthz || exit 1

# Run the MCP server when the container starts
CMD ["python", "-m", "mcp_server_qdrant"]