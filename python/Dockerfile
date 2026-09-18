# Python gRPC-микросервис из uv-workspace backend/services/python. SERVICE=<member> (пакет <SERVICE>-service)
FROM python:3.13-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

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
