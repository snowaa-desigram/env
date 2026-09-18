# Go gRPC-микросервис (go-zero). ENTRYPOINT_PATH=./cmd/<name>, ENTRYPOINT_NAME=<name>
FROM golang:1.25-alpine AS builder

ARG ENTRYPOINT_PATH
ARG ENTRYPOINT_NAME
ARG TARGETARCH

ENV CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH}

WORKDIR /build

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o /out/server ${ENTRYPOINT_PATH} \
 && cp -r ${ENTRYPOINT_PATH}/etc /out/etc

FROM alpine:3.22 AS runner

ARG ENTRYPOINT_NAME
ENV SERVICE_NAME=${ENTRYPOINT_NAME}

WORKDIR /app

COPY --from=builder /out/server ./server
COPY --from=builder /out/etc ./etc

CMD ["sh", "-c", "./server -f etc/${SERVICE_NAME}.yaml"]
