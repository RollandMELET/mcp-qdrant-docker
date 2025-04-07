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

# Add healthcheck with fallback to root path
HEALTHCHECK --interval=30s --timeout=30s --start-period=15s --retries=3 \
CMD curl -f http://localhost:8000/healthz || curl -f http://localhost:8000/ || exit 1

# Copy startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Run the MCP server when the container starts
CMD ["/app/start.sh"]