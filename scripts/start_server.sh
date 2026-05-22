#!/bin/bash
# Pindah ke folder project Laravel
cd /home/ec2-user/app

# Atur hak akses folder storage dan bootstrap agar web server (Apache/httpd) bisa nulis
echo "Mengatur permission folder Laravel..."
sudo chown -R ec2-user:apache /home/ec2-user/app
sudo chmod -R 775 /home/ec2-user/app/storage
sudo chmod -R 775 /home/ec2-user/app/bootstrap/cache

# Jalankan optimasi internal Laravel (jika composer sudah terinstall di server)
echo "Membersihkan cache Laravel..."
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

# Restart Apache Web Server agar membaca perubahan code terbaru
echo "Memulai ulang Apache Web Server..."
sudo systemctl restart httpd 