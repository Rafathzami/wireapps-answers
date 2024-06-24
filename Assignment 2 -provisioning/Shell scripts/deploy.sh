#!/bin/bash

# Clone the application repositories
git clone https://github.com/Rafathzami/webapp.git /home/builds/webapp
git clone https://github.com/Rafathzami/api.git /home/builds/api


cd /home/builds/webapp
npm install && run build
sudo cp -r /home/builds/webapp /var/www/webapp

cd /home/builds/api
npm install && run build
sudo cp -r /home/builds/api /var/www/api


sudo npm install -g pm2
pm2 start /var/www/webapp
pm2 start /var/www/api
