# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Set Go proxy to use Chinese mirror for faster downloads
ENV GOPROXY=https://goproxy.cn,direct
ENV GOPRIVATE=
ENV GOSUMDB=sum.golang.google.cn

# Install build dependencies
RUN apk add --no-cache git

# Copy go mod file first
COPY go.mod ./

# Initialize go.sum if it doesn't exist
RUN go mod download

# Copy source code
COPY . .

# Download any additional dependencies
RUN go mod tidy

# Build binary
RUN CGO_ENABLED=0 GOOS=linux go build -o short-drama-api main.go

# Run stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder
COPY --from=builder /app/short-drama-api .
# Docker 默认配置（mysql/redis 服务名、端口 9090）；可挂载自定义 config.yaml 覆盖
COPY --from=builder /app/config.docker.yaml ./config.yaml

EXPOSE 9090

CMD ["./short-drama-api"]
