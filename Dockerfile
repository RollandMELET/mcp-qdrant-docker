FROM python:3.11-slim

WORKDIR /app

# Install git, curl and netcat
RUN apt-get update && apt-get install -y git curl netcat-openbsd && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir qdrant-client fastembed uvicorn
RUN pip install --no-cache-dir git+https://github.com/qdrant/mcp-server-qdrant.git

# Environment variables for configuration
ENV QDRANT_URL=""
ENV QDRANT_API_KEY=""
ENV COLLECTION_NAME=""

# Expose the ports
EXPOSE 8000
EXPOSE 8001

# Add healthcheck using port 8001 (which is our fallback for health checking)
HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=5 \
CMD curl -f http://localhost:8001/ || exit 1

# Copy startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Run the MCP server when the container starts
CMD ["/app/start.sh"]