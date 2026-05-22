#!/bin/bash
# Pindah ke folder aplikasi
cd /home/ec2-user/app

# Masukkan path standar Linux
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

# PENGAMAN: Jika node/npm belum terinstall di server, kita pasang manual via NVM cepat
if ! command -v node &> /dev/null; then
    echo "Node.js tidak ditemukan karena dnf gagal. Menginstall via NVM otomatis..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 22
    nvm use 22
    # Daftarkan path binary nvm ke global PATH skrip ini
    export PATH=$PATH:$(dirname $(which node))
fi

# Cari lokasi npm hasil instalasi di atas
NPM_PATH=$(which npm)

echo "Menggunakan NPM dari: $NPM_PATH"

# Jalankan install dependency aplikasi
echo "Menjalankan npm install..."
$NPM_PATH install

# Cek dan pastikan PM2 terpasang
if ! command -v pm2 &> /dev/null; then
    echo "PM2 tidak ditemukan, menginstall secara global..."
    $NPM_PATH install pm2@latest -g
fi

# Jalankan ulang aplikasi menggunakan PM2
echo "Memulai aplikasi dengan PM2..."
pm2 delete all || true
pm2 start index.js --name "lks-node-app" 