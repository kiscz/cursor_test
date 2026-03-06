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

# Copy built files
COPY --from=builder /app/dist /usr/share/nginx/html

# 默认用 nginx.railway.conf（无 proxy，适合 Railway/Vercel 等）
# Docker Compose 需传 --build-arg USE_NGINX_PROXY=1 才用 nginx.conf（含 /api proxy）
ARG USE_NGINX_PROXY
COPY nginx.conf /tmp/nginx-docker.conf
COPY nginx.railway.conf /tmp/nginx-railway.conf
RUN if [ "$USE_NGINX_PROXY" = "1" ]; then cp /tmp/nginx-docker.conf /etc/nginx/conf.d/default.conf; else cp /tmp/nginx-railway.conf /etc/nginx/conf.d/default.conf; fi

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
