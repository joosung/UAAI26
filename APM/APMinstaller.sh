#!/bin/bash
 
#####################################################################################
#                                                                                   #
# * Ubuntu with AAI                                                                 #
# * Ubuntu 26.04.1-live-server                                        #
# * Apache 2.4.66 , MariaDB 15.2, Multi-PHP(base php8.5) setup shell script          #
# * Created Date    : 2026/09/28                                                    #
# * Created by  : Joo Sung ( webmaster@apachezone.com )                             #
#                                                                                   #

#####################################################################################

##########################################
#                                        #
#           repositories update          #
#                                        #
########################################## 

apt -y install git vm zip unzip sendmail glibc* zlib1g-dev gcc g++ make git autoconf autogen automake \
pkg-config libc-dev curl wget gnupg2 ca-certificates lsb-release apt-transport-https

apt -y update && sudo apt -y upgrade

sudo apt-get purge needrestart -y
##########################################
#                                        #
#           아파치2 및 HTTP2 설치            #
#                                        #
########################################## 

# apache2 설치
apt -y install apache2 libapache2-mod-fcgid

##########################################
#                                        #
#               firewalld                #
#                                        #
##########################################  

ufw enable -y

ufw allow 22

ufw allow 80

ufw allow 443

ufw allow 3306

ufw allow 9090

systemctl restart apache2

##########################################
#                                        #
#           httpd.conf   Setup           #
#                                        #
##########################################  

sed -i 's/#AddDefaultCharset/AddDefaultCharset/' /etc/apache2/conf-available/charset.conf
sed -i 's/ServerTokens OS/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
sed -i 's/ServerSignature On/ServerSignature Off/' /etc/apache2/conf-available/security.conf
sed -i 's/#<Directory \/>/<Directory \/>/' /etc/apache2/conf-available/security.conf
sed -i 's/#   AllowOverride None/   AllowOverride None/' /etc/apache2/conf-available/security.conf
sed -i '10s/#   Require all denied/   Require all denied/' /etc/apache2/conf-available/security.conf
sed -i 's/#<\/Directory>/<\/Directory>/' /etc/apache2/conf-available/security.conf
sed -i 's/#ServerName www.example.com/ServerName localhost/' /etc/apache2/sites-available/000-default.conf
sed -i '/ServerAdmin/i\                ServerName localhost' /etc/apache2/sites-available/default-ssl.conf
sed -i '/# Global configuration/i\ServerName localhost' /etc/apache2/apache2.conf

echo '<IfModule mod_userdir.c>
        UserDir public_html
        UserDir disabled root

        <Directory /var/www/*/public_html>
                AllowOverride FileInfo AuthConfig Limit Indexes
                Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec
                Require method GET POST OPTIONS
        </Directory>
</IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet ' > /etc/apache2/mods-available/userdir.conf

echo '# deny file, folder start with dot
<DirectoryMatch "^\.|\/\.">
    Require all denied
</DirectoryMatch>
 
# deny (log file, binary, certificate, shell script, sql dump file) access.
<FilesMatch "\.(?i:log|binary|pem|enc|crt|conf|cnf|sql|sh|key|yml|lock|gitignore)$">
    Require all denied
</FilesMatch>
 
# deny access.
<FilesMatch "(?i:composer\.json|contributing\.md|license\.txt|readme\.rst|readme\.md|readme\.txt|copyright|artisan|gulpfile\.js|package\.json|phpunit\.xml|access_log|error_log|gruntfile\.js|bower\.json|changelog\.md|console|legalnotice|license|security\.md|privacy\.md)$">
    Require all denied
</FilesMatch>
 
# Allow Lets Encrypt Domain Validation Program
<DirectoryMatch "\.well-known/acme-challenge/">
    Require all granted
</DirectoryMatch>
 
# Block .php file inside upload folder. uploads(wp), files(drupal), data(gnuboard).
<DirectoryMatch "/(uploads|default/files|data|wp-content/themes)/">
    <FilesMatch ".+\.php$">
        Require all denied
    </FilesMatch>
</DirectoryMatch>' > /etc/apache2/conf-available/deny-apache2.conf

ln -s /etc/apache2/conf-available/deny-apache2.conf /etc/apache2/conf-enabled/deny-apache2.conf

cp /root/UAAI/APM/index.html /var/www/html/
cp -f /root/UAAI/APM/index.html /usr/share/apache2/default-site/

apt -y install libapache2-mpm-itk

chmod 711 /home

systemctl restart apache2

apt -y install ssl-cert certbot python3-certbot-apache

##########################################
#                                        #
#      Multi PHP 및 라이브러리 install      #
#                                        #
########################################## 

sudo apt update -y

apt -y install php php-cli php8.5-fpm php-common php-mbstring php-ldap php-xmlrpc php-memcache php-memcached php-curl php-xml php-soap php-gd php-mysql php-bcmath php-dev php-pear libapache2-mod-php uwsgi-plugin-php libmcrypt-dev php-bz2 php-cgi php-dba php-enchant php-gmp php-snmp php-zip php-imagick 

sudo sudo a2enmod actions alias proxy_fcgi fcgid


cd /root/UAAI/APM

wget https://github.com/maxmind/geoip-api-c/releases/download/v1.6.12/GeoIP-1.6.12.tar.gz
tar -xzvf GeoIP-1.6.12.tar.gz
cd GeoIP-1.6.12
./configure
make && make install

sed -i 's/#GeoIPDBFile/GeoIPDBFile/' /etc/apache2/mods-available/geoip.conf
sed -i 's/GeoIPEnable Off/GeoIPEnable On/' /etc/apache2/mods-available/geoip.conf

sudo a2enmod geoip
sudo a2enmod http2
sudo a2enmod php8.5
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2enmod ssl
a2enmod proxy_fcgi setenvif
sudo a2dismod -f autoindex
sudo a2enconf php8.5-fpm

systemctl restart apache2

systemctl enable php8.5-fpm
systemctl start php8.5-fpm

cp -av /etc/php/8.5/fpm/php.ini /etc/php/8.5/fpm/php.ini.original
sed -i 's/short_open_tag = Off/short_open_tag = On/' /etc/php/8.5/fpm/php.ini
sed -i 's/expose_php = On/expose_php = Off/' /etc/php/8.5/fpm/php.ini
sed -i 's/display_errors = Off/display_errors = On/' /etc/php/8.5/fpm/php.ini
sed -i 's/;error_log = php_errors.log/error_log = php_errors.log/' /etc/php/8.5/fpm/php.ini
sed -i 's/error_reporting = E_ALL \& ~E_DEPRECATED/error_reporting = E_ALL \& ~E_NOTICE \& ~E_DEPRECATED \& ~E_USER_DEPRECATED/' /etc/php/8.5/fpm/php.ini
sed -i 's/variables_order = "GPCS"/variables_order = "EGPCS"/' /etc/php/8.5/fpm/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 100M/' /etc/php/8.5/fpm/php.ini
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 100M/' /etc/php/8.5/fpm/php.ini
sed -i 's/;date.timezone =/date.timezone = "Asia\/Seoul"/' /etc/php/8.5/fpm/php.ini
sed -i 's/session.gc_maxlifetime = 1440/session.gc_maxlifetime = 86400/' /etc/php/8.5/fpm/php.ini
sed -i 's/disable_functions =/disable_functions = system,exec,passthru,proc_open,popen,curl_multi_exec,parse_ini_file,show_source/' /etc/php/8.5/fpm/php.ini
sed -i 's/allow_url_fopen = On/allow_url_fopen = Off/' /etc/php/8.5/fpm/php.ini 

apt -y install php-ssh2

apt -y install udisks2-btrfs

mkdir /etc/skel/public_html

mkdir /etc/apache2/logs/

chmod 707 /etc/skel/public_html

chmod 700 /root/UAAI/adduser.sh

chmod 700 /root/UAAI/deluser.sh

chmod 700 /root/UAAI/restart.sh

chmod 700 /root/UAAI/clamav.sh

cp /root/UAAI/APM/skel/index.html /etc/skel/public_html/

systemctl restart apache2

echo '<?php
phpinfo();
?>' >> /var/www/html/phpinfo.php

##########################################
#                                        #
#        mariadb install & Setup         #
#                                        #
##########################################

apt -y install mariadb-server mariadb-client

echo "[mysql]
default-character-set = utf8mb4
 
[mysqld]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
 
query_cache_type = ON
query_cache_limit = 1M
query_cache_size = 16M
 
sql_mode = NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
  
[client]
default-character-set = utf8mb4" > /etc/mysql/mariadb.conf.d/mysql-aai.cnf

##########################################
#                                        #
#        운영 및 보안 관련 추가 설정            #
#                                        #
##########################################

cd /root/UAAI/APM

#chkrootkit 설치
apt -y install chkrootkit

#fail2ban 설치
apt -y install fail2ban
sed -i 's/#ignoreip/ignoreip/' /etc/fail2ban/jail.conf
systemctl restart fail2ban

#arpwatch 설치
apt -y install arpwatch

#clamav 설치
apt -y install clamav clamav-daemon

lsof /var/log/clamav/freshclam.log
pkill -15 -x freshclam
/etc/init.d/clamav-freshclam stop
freshclam
/etc/init.d/clamav-freshclam start

mkdir /virus
mkdir /backup

/etc/init.d/clamav-daemon stop

#mod_security 설치
apt -y install libapache2-mod-security2

cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf

mv /usr/share/modsecurity-crs /usr/share/modsecurity-crs.bk
git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /usr/share/modsecurity-crs

sed -i 's/IncludeOptional \/usr\/share\/modsecurity-crs\/owasp-crs.load/#IncludeOptional \/usr\/share\/modsecurity-crs\/owasp-crs.load/' /etc/apache2/mods-enabled/security2.conf
sed -i '/<\/IfModule>/i\        IncludeOptional \/usr\/share\/modsecurity-crs\/*.conf' /etc/apache2/mods-enabled/security2.conf
sed -i '/<\/IfModule>/i\        IncludeOptional \/usr\/share\/modsecurity-crs\/rules\/*.conf' /etc/apache2/mods-enabled/security2.conf

systemctl restart apache2

#memcached 설치
apt -y install memcached

#mod_expires 설정
a2enmod expires
systemctl restart apache2

echo "#mod_expires configuration" > /tmp/apache2.conf_tempfile
echo "<IfModule mod_expires.c>"   >> /tmp/apache2.conf_tempfile
echo "    ExpiresActive On"    >> /tmp/apache2.conf_tempfile
echo "    ExpiresDefault \"access plus 1 days\""    >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType text/css \"access plus 1 days\""       >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType text/javascript \"access plus 1 days\""      >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType text/x-javascript \"access plus 1 days\""        >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType application/x-javascript \"access plus 1 days\"" >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType application/javascript \"access plus 1 days\""    >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType image/jpeg \"access plus 1 days\""    >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType image/gif \"access plus 1 days\""       >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType image/png \"access plus 1 days\""      >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType image/bmp \"access plus 1 days\""        >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType image/cgm \"access plus 1 days\"" >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType image/tiff \"access plus 1 days\""       >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType audio/basic \"access plus 1 days\""      >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType audio/midi \"access plus 1 days\""        >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType audio/mpeg \"access plus 1 days\""        >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType audio/x-aiff \"access plus 1 days\""  >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType audio/x-mpegurl \"access plus 1 days\"" >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType audio/x-pn-realaudio \"access plus 1 days\""   >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType audio/x-wav \"access plus 1 days\""   >> /tmp/apache2.conf_tempfile
echo "    ExpiresByType application/x-shockwave-flash \"access plus 1 days\""   >> /tmp/apache2.conf_tempfile
echo "</IfModule>"   >> /tmp/apache2.conf_tempfile
cat /tmp/apache2.conf_tempfile > /etc/apache2/mods-available/expires.conf
rm -f /tmp/apache2.conf_tempfile

systemctl restart apache2

##########################################
#                                        #
#            Local SSL 설정               #
#                                        #
##########################################

mv /root/UAAI/APM/etc/cron.daily/backup /etc/cron.daily/
mv /root/UAAI/APM/etc/cron.daily/check_chkrootkit /etc/cron.daily/
mv /root/UAAI/APM/etc/cron.daily/letsencrypt-renew /etc/cron.daily/

chmod 700 /etc/cron.daily/backup
chmod 700 /etc/cron.daily/check_chkrootkit
chmod 700 /etc/cron.daily/letsencrypt-renew

echo "00 20 * * * /etc/cron.daily/check_chkrootkit" >> /etc/crontab
echo "01 02,14 * * * /etc/cron.daily/letsencrypt-renew" >> /etc/crontab
echo "01 01 * * 7 /root/UAAI/clamav.sh" >> /etc/crontab

#openssl 로 디피-헬만 파라미터(dhparam) 키 만들기 둘중 하나 선택
#openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096
openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

ioncube loader 설치 및 설정
cd /tmp && wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
tar xfz ioncube_loaders_lin_*.gz
sudo mv /tmp/ioncube /usr/lib/php/ioncube
rm -rf /tmp/ioncube*

sed -i '/[ffi]/i\zend_extension = /usr/lib/php/ioncube/ioncube_loader_lin_8.5.so' /etc/php/8.5/fpm/php.ini

#중요 폴더 및 파일 링크
ln -s /etc/letsencrypt /root/UAAI/letsencrypt
ln -s /etc/apache2 /root/UAAI/apache2
ln -s /etc/mysql/conf.d/mysql.cnf /root/UAAI/mysql.cnf

cd /root/UAAI

systemctl restart apache2

mariadb-secure-installation

##########################################
#                                        #
#              cockpit 설치               #
#                                        #
##########################################
cd /root/UAAI

sudo apt -y install cockpit

sudo systemctl start cockpit

sh /root/UAAI/restart.sh

echo ""
echo ""
echo "축하 드립니다. APMinstaller 모든 작업이 끝났습니다."

exit 0