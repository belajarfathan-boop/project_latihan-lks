#!/bin/bash
# Pindah ke folder aplikasi
cd /home/ec2-user/app

# Masukkan path standar Linux
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

# PAKSA NVM menggunakan folder /tmp agar terhindar dari Permission Denied
export NVM_DIR="/tmp/.nvm"

if [ ! -d "$NVM_DIR" ]; then
    echo "Membuat folder NVM di /tmp..."
    mkdir -p "$NVM_DIR"
fi

# Install NVM secara lokal di folder /tmp
echo "Menginstall NVM ke $NVM_DIR..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Load NVM ke dalam skrip ini
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js 22 lewat NVM yang sudah di-load
echo "Menginstall Node.js versi 22..."
nvm install 22
nvm use 22

# Ambil lokasi node dan npm yang baru saja terinstall di /tmp
NODE_BIN_DIR=$(dirname $(which node))
export PATH=$NODE_BIN_DIR:$PATH

echo "Node.js berhasil aktif di: $(which node)"
echo "NPM berhasil aktif di: $(which npm)"

# Jalankan install dependency aplikasi
echo "Menjalankan npm install aplikasi..."
npm install

# Install PM2 lokal di environment NVM /tmp jika belum ada
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    npm install pm2@latest -g
fi

# Jalankan ulang aplikasi menggunakan PM2
echo "Memulai ulang aplikasi dengan PM2..."
pm2 delete all || true
pm2 start index.js --name "lks-node-app" 