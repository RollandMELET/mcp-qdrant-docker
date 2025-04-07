FROM python:3.11-slim

WORKDIR /app

# Install git and curl
RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir qdrant-client fastembed uvicorn
RUN pip install --no-cache-dir git+https://github.com/qdrant/mcp-server-qdrant.git

# Environment variables for configuration
ENV QDRANT_URL=""
ENV QDRANT_API_KEY=""
ENV COLLECTION_NAME=""

# Expose the port the server runs on
EXPOSE 8000

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/healthz || exit 1

# Run the MCP server when the container starts
CMD ["python", "-m", "mcp_server_qdrant.main"]