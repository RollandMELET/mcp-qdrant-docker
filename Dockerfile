FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir uvicorn fastembed qdrant-client
RUN pip install --no-cache-dir uvx
RUN pip install --no-cache-dir mcp-server-qdrant

ENV QDRANT_URL=""
ENV QDRANT_API_KEY=""
ENV COLLECTION_NAME=""

EXPOSE 8000

CMD ["python", "-m", "mcp_server_qdrant"]