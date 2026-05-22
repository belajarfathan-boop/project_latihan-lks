#!/bin/bash
# Pindah ke folder aplikasi
cd /home/ec2-user/app

# Inject path environment standar Linux secara luas
export PATH=$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.nvm/versions/node/$(node -v)/bin

# Ambil lokasi npm secara dinamis
NPM_PATH=$(which npm)
PM2_PATH=$(which pm2)

# Jika PM2 belum terinstall, install secara global menggunakan path npm yang ditemukan
if [ -z "$PM2_PATH" ]; then
    echo "PM2 tidak ditemukan, menginstall via $NPM_PATH..."
    sudo $NPM_PATH install pm2@latest -g
    PM2_PATH=$(which pm2)
fi

# Jalankan install dependency aplikasi
echo "Menjalankan npm install..."
$NPM_PATH install

# Jalankan ulang aplikasi menggunakan PM2 secara dinamis
echo "Memulai aplikasi dengan PM2..."
$PM2_PATH delete all || true
$PM2_PATH start index.js --name "lks-node-app" 