#!/bin/bash

sudo apt-get update
sudo apt-get install -y nginx curl git

curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs


sudo apt-get install -y certbot python3-certbot-nginx


sudo tee /etc/nginx/conf.d/web.example.com >/dev/null <<EOF
server {
    listen 80;
    server_name web.example.com;

    location / {
        proxy_pass http://localhost:5000;  
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

sudo tee /etc/nginx/conf.d/api.example.com >/dev/null <<EOF
server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://localhost:5001;  
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF


sudo ln -s /etc/nginx/conf.d/web.example.com /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/conf.d/api.example.com /etc/nginx/sites-enabled/


sudo nginx -t
sudo systemctl reload nginx


sudo certbot --nginx -d web.example.com -d api.example.com --non-interactive --agree-tos --email web-api@example.com
