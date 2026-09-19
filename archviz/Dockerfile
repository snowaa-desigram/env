# archviz-render (только dev): графы зависимостей и вызовов Go/Python + рендер .dot от core. Запуск — make archviz.
FROM golang:1.25-bookworm

# graphviz — dot для всех svg; uv — pydeps в окружении workspace (пин как в python/Dockerfile и Makefile `test`)
ARG UV_VERSION=0.9.30
# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends graphviz python3 python3-pip \
 && rm -rf /var/lib/apt/lists/* \
 && pip3 install --no-cache-dir --break-system-packages "uv==${UV_VERSION}"

# goda — граф пакетов, go-callvis — граф вызовов по main-пакету (репозиторий ondrajz/go-callvis, но go.mod объявляет путь ofabry/go-callvis)
ARG GODA_VERSION=v0.10.1
ARG GOCALLVIS_VERSION=v0.7.1
RUN go install github.com/loov/goda@${GODA_VERSION} \
 && go install github.com/ofabry/go-callvis@${GOCALLVIS_VERSION}

ENV UV_PROJECT_ENVIRONMENT=/tmp/venv \
    UV_LINK_MODE=copy \
    UV_HTTP_TIMEOUT=300 \
    GOFLAGS=-mod=mod

COPY render.sh /archviz/render.sh
WORKDIR /src
ENTRYPOINT ["/archviz/render.sh"]
