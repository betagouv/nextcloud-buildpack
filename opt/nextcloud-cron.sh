#!/bin/bash
#
if [ -n "$DEBUG" ]; then
  set -x
fi
#
# init php with includes
#
basedir="/app"
echo "# prepare includes php ini"
php_conf_dir="vendor/php/etc/conf.d/"
erb $basedir/conf/php/php-pgsql.ini.erb > ${php_conf_dir}/php-pgsql.ini
erb $basedir/conf/php/php-redis-session.ini.erb > ${php_conf_dir}/php-redis-session.ini
erb $basedir/conf/php/php-opcache.ini.erb > ${php_conf_dir}/php-opcache.ini
erb $basedir/conf/php/php-apcu.ini.erb > ${php_conf_dir}/php-apcu.ini
echo "# End init"


php -f nextcloud/cron.php