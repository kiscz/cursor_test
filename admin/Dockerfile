# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# API URL for production (Railway: VITE_API_BASE_URL=https://${{Backend.RAILWAY_PUBLIC_DOMAIN}}/api)
ARG VITE_API_BASE_URL
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

# Copy package files
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

# Build
RUN npm run build

# Run stage
FROM nginx:alpine

# envsubst 用于替换 PORT（nginx:alpine 含 gettext）
RUN apk add --no-cache gettext

# Copy built files
COPY --from=builder /app/dist /usr/share/nginx/html

# 默认用 nginx.railway.conf（无 proxy，Railway 需监听 $PORT）
# Docker Compose 传 USE_NGINX_PROXY=1 用 nginx.conf（含 /api proxy）
ARG USE_NGINX_PROXY
COPY nginx.conf /tmp/nginx-docker.conf
COPY nginx.railway.conf /tmp/nginx-railway.conf
RUN if [ "$USE_NGINX_PROXY" = "1" ]; then cp /tmp/nginx-docker.conf /etc/nginx/conf.d/default.conf; else cp /tmp/nginx-railway.conf /etc/nginx/conf.d/default.conf.template; fi

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80 8080

# Railway: entrypoint 用 envsubst 替换 $PORT 后启动 nginx
# Docker Compose (USE_NGINX_PROXY=1): 直接用 nginx.conf，需覆盖 CMD
ENTRYPOINT ["/docker-entrypoint.sh"]
