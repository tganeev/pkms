#!/bin/bash

# Настройки сервера
SERVER_HOST="159.194.207.97"
SERVER_USER="root"
SERVER_PATH="/opt/pkms"

echo "🚀 Starting deployment to $SERVER_HOST..."

# Собираем backend
echo "📦 Building backend..."
cd backend
mvn clean package -DskipTests
cd ..

# Собираем frontend
echo "🎨 Building frontend..."
cd frontend
npm install --legacy-peer-deps
npm run build
cd ..

# Копируем файлы на сервер
echo "📤 Copying files to server..."

# Копируем backend JAR
scp backend/target/*.jar $SERVER_USER@$SERVER_HOST:$SERVER_PATH/backend/

# 🔥 ДОБАВИТЬ: Копируем исходники для сборки в Docker
scp -r backend/src $SERVER_USER@$SERVER_HOST:$SERVER_PATH/backend/
scp backend/pom.xml $SERVER_USER@$SERVER_HOST:$SERVER_PATH/backend/



# Копируем build фронтенда
scp -r frontend/build $SERVER_USER@$SERVER_HOST:$SERVER_PATH/frontend/



# Копируем docker-compose
scp docker-compose.yml $SERVER_USER@$SERVER_HOST:$SERVER_PATH/

# Выполняем команды на сервере
echo "🔄 Updating containers..."
ssh $SERVER_USER@$SERVER_HOST << 'ENDSSH'
cd /opt/pkms

# Сохраняем текущие SSL сертификаты если они есть
if [ ! -d "frontend/ssl" ] && [ -d "templates/ssl" ]; then
    echo "Restoring SSL certificates from template..."
    cp -r templates/ssl frontend/
fi

# Восстанавливаем рабочий nginx.conf если его нет
if [ ! -f "frontend/nginx.conf" ] && [ -f "templates/nginx.conf" ]; then
    echo "Restoring nginx.conf from template..."
    cp templates/nginx.conf frontend/nginx.conf
fi

# Проверяем, что nginx.conf существует и правильный
if [ ! -f "frontend/nginx.conf" ]; then
    echo "❌ nginx.conf not found! Creating default..."
    cat > frontend/nginx.conf << 'NGINXEOF'
user nginx;

server {
    listen 80;
    server_name localhost 127.0.0.1;
    root /usr/share/nginx/html;
    index index.html;
    
    location /static/ {
        alias /usr/share/nginx/html/static/;
    }
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api/ {
        proxy_pass http://backend:8080/api/;
    }
}

server {
    listen 80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl default_server;
    server_name _;
    
    ssl_certificate /etc/nginx/ssl/certificate.crt;
    ssl_certificate_key /etc/nginx/ssl/private.key;
    
    root /usr/share/nginx/html;
    index index.html;
    
    location /static/ {
        alias /usr/share/nginx/html/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api/ {
        proxy_pass http://backend:8080/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINXEOF
fi

# Проверяем SSL сертификаты
if [ ! -f "frontend/ssl/certificate.crt" ] || [ ! -f "frontend/ssl/private.key" ]; then
    echo "🔐 Generating SSL certificates..."
    mkdir -p frontend/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout frontend/ssl/private.key \
      -out frontend/ssl/certificate.crt \
      -subj "/C=RU/ST=Moscow/L=Moscow/O=PKMS/CN=my-pkms.ru"
fi

# Останавливаем старые контейнеры
docker-compose down

# Пересобираем
echo "🏗️  Building containers..."
docker-compose build --no-cache

# Запускаем
echo "🚀 Starting containers..."
docker-compose up -d

# Ждем готовности
sleep 10

# Проверяем права
docker exec pkms-frontend chown -R nginx:nginx /usr/share/nginx/html 2>/dev/null || true
docker exec pkms-frontend chmod -R 755 /usr/share/nginx/html 2>/dev/null || true

# Перезагружаем nginx
docker exec pkms-frontend nginx -s reload 2>/dev/null || true

# Проверяем здоровье
echo ""
echo "🔍 Running health check..."
./health-check.sh 2>/dev/null || echo "Health check not available"

# Очистка
docker image prune -f

echo ""
echo "✅ Deployment completed!"
ENDSSH

echo ""
echo "🌐 Application available at: https://$SERVER_HOST"
