# Python gRPC-микросервис из uv-workspace backend/services/python. SERVICE=<member> (пакет <SERVICE>-service)
FROM python:3.13-slim

# uv — из PyPI, а не COPY --from=ghcr.io: тег :latest заставлял ходить в ghcr.io на каждую сборку
# (TLS handshake timeout ронял весь `make dev`), а версия плавала. Пин = та же, что в Makefile `test`.
ARG UV_VERSION=0.9.30
RUN pip install --no-cache-dir "uv==${UV_VERSION}"

ARG SERVICE
ENV SERVICE=${SERVICE} \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    PYTHONUNBUFFERED=1

WORKDIR /app

# зависимости — отдельным слоем (только pyproject'ы + lock)
COPY pyproject.toml uv.lock ./
COPY common/pyproject.toml common/
COPY ${SERVICE}/pyproject.toml ${SERVICE}/
RUN uv sync --frozen --package ${SERVICE}-service --no-install-workspace --no-dev

COPY . .
RUN uv sync --frozen --package ${SERVICE}-service --no-dev

EXPOSE 50051

CMD ["sh", "-c", ".venv/bin/${SERVICE}-service"]
