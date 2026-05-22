#!/bin/bash
# Pindah ke folder aplikasi
cd /home/ec2-user/app

# Daftarkan path secara absolut demi CodeDeploy
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

# Pastikan PM2 terpasang secara global menggunakan path absolut npm
if ! command -v pm2 &> /dev/null
then
    echo "PM2 tidak ditemukan, menginstall via path absolut..."
    sudo /usr/bin/npm install pm2@latest -g
fi

# Jalankan install dependency aplikasi menggunakan path absolut
echo "Menjalankan npm install aplikasi..."
/usr/bin/npm install

# Jalankan ulang aplikasi menggunakan path absolut PM2
echo "Memulai ulang aplikasi dengan PM2..."
/usr/bin/pm2 delete all || true
/usr/bin/pm2 start index.js --name "lks-node-app" 