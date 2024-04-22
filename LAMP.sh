#!/bin/bash


# Updating and Installing Dependencies
sudo apt update
sudo apt install -y ca-certificates apt-transport-https software-properties-common lsb-release
sudo add-apt-repository -y ppa:ondrej/php
sudo apt install -y apache2 php8.3 git
sudo apt install -y php8.3-curl php8.3-dom php8.3-mbstring php8.3-xml zip unzip php8.3-mysql php8.3-sqlite3 mysql-server

touch /root/monitor.log
echo $(php -m) >> /root/monitor.log

# Enabling Rewrite
sudo a2enmod rewrite
sudo systemctl restart
echo "Apache Restarted" >> /root/monitor.log


# Installing Composer
echo "Installing Composer" >> /root/monitor.log
cd /usr/bin
curl -sS https://getcomposer.org/installer | sudo php
echo "Composer Installed" >> /root/monitor.log

# Allowing Composer run in root
echo "Allowing composer run in root" >> /root/monitor.log
export COMPOSER_ALLOW_SUPERUSER=1
echo $($COMPOSER_ALLOW_SUPERUSER) >> /root/monitor.log
echo "done" >> /root/monitor.log

# Changing Composer name
echo "Changing composer name" >> /root/monitor.log
mv composer.phar composer
echo $(composer) >> /root/monitor.log

# Cloning Repo
echo "Cloning github repo" >> /root/monitor.log
cd /var/www/
sudo git clone https://github.com/laravel/laravel.git
echo
cd laravel
echo "Done Cloning" >> /root/monitor.log

# Installing Composer to project
echo "Installing Composer" >> /root/monitor.log
composer install --optimize-autoloader --no-dev --no-interaction
echo "Composer Install Successful" >> /root/monitor.log
composer update --no-interaction
echo "Done"

# Setting up .env
cp .env.example .env
sed -i 's/^\(APP_URL=\).*/\1192.168.50.11/' .env
sed -i 's/^\(APP_ENV=\).*/\1production/' .env
php artisan key:generate

# Changing ownership
chown -R www-data storage
chown -R www-data bootstrap/cache

# Writing to Config File
echo "Writing to config file" >> /root/monitor.log
cd /etc/apache2/sites-available/
touch laravel.conf
echo "<VirtualHost *:80>
  ServerName 192.168.33.11
  DocumentRoot /var/www/laravel/public

  <Directory /var/www/laravel/public>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
  </Directory>

  ErrorLog ${APACHE_LOG_DIR}/demo-error.log
  CustomLog ${APACHE_LOG_DIR}/demo-access.log combined
  </VirtualHost>" > laravel.conf

# Enabling Config file
sudo a2ensite laravel.conf
echo $(apache2ctl -t) >> /root/monitor.log
systemctl restart apache2

# Setting up DB
sudo mysql -uroot -e "CREATE DATABASE laravel_db;"
sudo mysql -uroot -e "CREATE USER 'laravel'@'localhost' IDENTIFIED BY 'password';"
sudo mysql -uroot -e "FLUSH PRIVILEGES;"

# Error Fixing
sudo sed -i '/^\[ExtensionList\]/a extension=pdo_sqlite.so' /etc/php/8.3/cli/php.ini

# Migrating DB
cd /var/www/laravel
php artisan migrate --force

# Setting Permissions
chmod 755 /var/www/laravel/database/
touch /var/www/laravel/database/database.sqlite
chown www-data:www-data /var/www/laravel/database/database.sqlite
chmod u+w /var/www/laravel/database/database.sqlite

  

