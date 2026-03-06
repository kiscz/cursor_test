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

# Railway: VITE_API_BASE_URL 已设置则用 nginx.railway.conf（无 proxy）
# Docker Compose: 用 nginx.conf（含 /api proxy）
ARG VITE_API_BASE_URL
COPY nginx.conf /tmp/nginx-docker.conf
COPY nginx.railway.conf /tmp/nginx-railway.conf
RUN if [ -n "$VITE_API_BASE_URL" ]; then cp /tmp/nginx-railway.conf /etc/nginx/conf.d/default.conf; else cp /tmp/nginx-docker.conf /etc/nginx/conf.d/default.conf; fi

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
