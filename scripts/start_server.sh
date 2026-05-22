#!/bin/bash
# Pindah ke folder project Laravel
cd /home/ec2-user/app

# Inject path standar Linux secara luas
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

# PENGAMAN: Jika PHP beneran belum terinstall di server, kita paksa install sekarang
if ! command -v php &> /dev/null; then
    echo "PHP tidak ditemukan. Mencoba menginstall PHP secara otomatis..."
    sudo dnf clean all
    sudo dnf install -y php php-cli php-common php-mbstring php-xml php-fpm
fi

# Cari lokasi binary php secara pasti
PHP_PATH=$(which php || echo "/usr/bin/php")
echo "Menggunakan PHP dari: $PHP_PATH"

# Atur hak akses folder storage dan bootstrap Laravel
echo "Mengatur permission folder Laravel..."
sudo chown -R ec2-user:apache /home/ec2-user/app
sudo chmod -R 775 /home/ec2-user/app/storage
sudo chmod -R 775 /home/ec2-user/app/bootstrap/cache

# Jalankan optimasi internal Laravel menggunakan path absolut PHP yang valid
echo "Membersihkan cache Laravel..."
sudo $PHP_PATH artisan config:clear || echo "Skip config:clear"
sudo $PHP_PATH artisan cache:clear || echo "Skip cache:clear"
sudo $PHP_PATH artisan route:clear || echo "Skip route:clear"
sudo $PHP_PATH artisan view:clear || echo "Skip view:clear"

# Restart Apache Web Server agar membaca perubahan code terbaru
echo "Memulai ulang Apache Web Server..."
sudo systemctl restart httpd 