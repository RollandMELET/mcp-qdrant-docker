FROM python:3.11-slim

WORKDIR /app

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir uvicorn
RUN pip install --no-cache-dir fastembed
RUN pip install --no-cache-dir qdrant-client
RUN pip install --no-cache-dir mcp-server-qdrant

# Environment variables for configuration
ENV QDRANT_URL=""
ENV QDRANT_API_KEY=""
ENV COLLECTION_NAME=""

# Expose the port the server runs on
EXPOSE 8000

# Run the MCP server when the container starts
# Note: The correct way to run the module
CMD ["python", "-m", "mcp_server_qdrant.main"]