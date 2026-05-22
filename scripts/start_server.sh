#!/bin/bash
cd /home/ec2-user/app

# Install dependency aplikasi jika belum ada
npm install

# Install pm2 secara global untuk manajemen proses Node.js di server
sudo npm install pm2@latest -g

# Matikan proses lama (jika ada) dan nyalakan yang baru
pm2 delete all || true
pm2 start index.js --name "lks-node-app" 