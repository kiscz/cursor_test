#!/bin/sh
set -e
# Railway: 有 template 则用 envsubst 替换 $PORT 后生成配置
if [ -f /etc/nginx/conf.d/default.conf.template ]; then
  export PORT="${PORT:-8080}"
  envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
fi
exec nginx -g "daemon off;"
