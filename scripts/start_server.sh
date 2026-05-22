#!/bin/bash
cd /home/ec2-user/app

# PENGAMAN: Menunggu proses install latar belakang EC2 selesai (max 5 menit)
echo "Menunggu dnf lock dilepaskan oleh sistem..."
for i in {1..30}; do
    if ! sudo fuser /var/lib/dnf/lock >/dev/null 2>&1; then
        echo "Sistem siap, melanjutkan deployment."
        break
    fi
    echo "Sistem masih sibuk, menunggu 10 detik lagi... ($i/30)"
    sleep 10
done

# Daftarkan ulang path global environment agar dikenali CodeDeploy
export PATH=$PATH:/usr/local/bin:/usr/bin:/bin

# Jika npm belum siap juga, kita paksa install ulang dengan aman
if ! command -v npm &> /dev/null
then
    echo "Menginstall Node.js secara paksa..."
    curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
    sudo dnf install -y nodejs
fi

# Pastikan PM2 terinstall global
if ! command -v pm2 &> /dev/null
then
    sudo npm install pm2@latest -g
fi

# Amankan instalasi modul aplikasi lo
npm install

# Jalankan ulang aplikasi menggunakan PM2
pm2 delete all || true
pm2 start index.js --name "lks-node-app" 