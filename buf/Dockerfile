# Тулчейн генерации gRPC-кода: buf + локальные плагины (без зависимости от buf.build)
FROM golang:1.25-alpine AS goplugins
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.12 \
 && go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1

FROM bufbuild/buf:1.73.0 AS buf

FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends protobuf-compiler protobuf-compiler-grpc git \
 && rm -rf /var/lib/apt/lists/*
COPY --from=buf /usr/local/bin/buf /usr/local/bin/buf
COPY --from=goplugins /go/bin/protoc-gen-go /go/bin/protoc-gen-go-grpc /usr/local/bin/
WORKDIR /workspace
ENTRYPOINT ["buf"]
