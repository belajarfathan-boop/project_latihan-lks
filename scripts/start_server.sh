#!/bin/bash
cd /home/ec2-user/app

# Memuat profile agar command node/npm langsung terbaca di session CodeDeploy
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
export PATH=$PATH:/usr/local/bin:/usr/bin

# Cek darurat: Jika npm benar-benar belum terinstall, paksa install langsung di sini
if ! command -v npm &> /dev/null
then
    echo "npm tidak ditemukan, menginstall Node.js..."
    curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
    sudo dnf install -y nodejs
fi

# Install pm2 jika belum ada
if ! command -v pm2 &> /dev/null
then
    sudo npm install pm2@latest -g
fi

# Jalankan instalasi dependencies aplikasi lo
npm install

# Restart aplikasi menggunakan PM2
pm2 delete all || true
pm2 start index.js --name "lks-node-app" 