# Railway 部署用 Dockerfile（根目录）
# 构建后端服务

FROM golang:1.21-alpine AS builder

WORKDIR /app

# Set Go proxy
ENV GOPROXY=https://goproxy.cn,direct
ENV GOPRIVATE=
ENV GOSUMDB=sum.golang.google.cn

# Install build dependencies
RUN apk add --no-cache git

# Copy go mod and go sum files first
COPY backend/go.mod backend/go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY backend/ .

# Ensure dependencies are up to date
RUN go mod tidy && go mod verify

# Build binary
RUN CGO_ENABLED=0 GOOS=linux go build -o short-drama-api main.go

# Run stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/short-drama-api .
# Copy default config
COPY backend/config.docker.yaml ./config.yaml

EXPOSE 9090

CMD ["./short-drama-api"]
