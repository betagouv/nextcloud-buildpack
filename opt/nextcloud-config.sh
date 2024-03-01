#!/bin/bash
#
if [ -n "$DEBUG" ]; then
  set -x
fi


basedir="/app"

if [[ -z "$DATABASE_URL" ]]; then
  echo >&2 "The environment variable DATABASE_URL must be set. The default user should be updated with the CREATEROLE privilege."
  exit -1
fi
if [[ -z "$REDIS_URL" ]]; then
  echo >&2 "The environment variable REDIS_URL must be set."
  exit -1
fi


#
# common libs
#
parse_scheme () {
    echo "$@" | python3 -c 'from urllib.parse import urlparse; import sys; print(urlparse(sys.stdin.read()).scheme)'
}

parse_user () {
    echo "$@" | python3 -c 'from urllib.parse import urlparse; import sys; print(urlparse(sys.stdin.read()).username)'
}

parse_pass () {
    echo "$@" | python3 -c 'from urllib.parse import urlparse; import sys; print(urlparse(sys.stdin.read()).password)'
}

parse_host () {
    echo "$@" | python3 -c 'from urllib.parse import urlparse; import sys; print(urlparse(sys.stdin.read()).hostname)'
}

parse_port () {
    echo "$@" | python3 -c 'from urllib.parse import urlparse; import sys; print(urlparse(sys.stdin.read()).port)'
}

parse_path () {
    echo "$@" | python3 -c 'from urllib.parse import urlparse; import sys; print(urlparse(sys.stdin.read()).path.strip("/"))'
}

eval "DATABASE_USER=$(parse_user $DATABASE_URL)"
eval "DATABASE_PASS=$(parse_pass $DATABASE_URL)"
eval "DATABASE_HOST=$(parse_host $DATABASE_URL)"
eval "DATABASE_PORT=$(parse_port $DATABASE_URL)"
eval "DATABASE_NAME=$(parse_path $DATABASE_URL)"

export DATABASE_USER
export DATABASE_PASS
export DATABASE_HOST
export DATABASE_PORT
export DATABASE_NAME

eval "REDIS_PASS=$(parse_pass $REDIS_URL/)"
eval "REDIS_HOST=$(parse_host $REDIS_URL/)"
eval "REDIS_PORT=$(parse_port $REDIS_URL/)"

export REDIS_PASS
export REDIS_HOST
export REDIS_PORT

( cd nextcloud
#
# is installed ?
#
if [[ ! -f config/config.php ]] ; then
  echo "# prepare config.php template"
  export NC_CONFIG_TEMPLATE="base secret s3 redis smtp oidc db installed"
  for c in $NC_CONFIG_TEMPLATE; do
    echo "# $c.config.php"
    [ -f "$basedir/conf/nextcloud/$c.config.php" ] && cp $basedir/conf/nextcloud/$c.config.php config/$c.config.php
  done
fi
)

# export OC_PASS=$NC_ADMIN_PASSWORD
# php occ user:resetpassword ${NC_ADMIN_USER} --password-from-env

# trusted_domains
if [ -n "${NC_TRUSTED_DOMAINS+x}" ]; then
    echo "Setting trusted domains...";
    NC_TRUSTED_DOMAIN_IDX=0;
    for DOMAIN in $NC_TRUSTED_DOMAINS ; do
        DOMAIN=$(echo "$DOMAIN" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//');
        php occ config:system:set trusted_domains $NC_TRUSTED_DOMAIN_IDX --value=$DOMAIN
        NC_TRUSTED_DOMAIN_IDX=$((NC_TRUSTED_DOMAIN_IDX+1));
    done;
fi

mkdir -p "$basedir/nextcloud/data/appdata_${NC_INSTANCEID}/appstore"
touch  $basedir/nextcloud/data/.ocdata
touch  "$basedir/nextcloud/data/appdata_${NC_INSTANCEID}/appstore/apps.json"

#
# init php with includes
#
echo "# prepare includes php ini"
php_conf_dir="vendor/php/etc/conf.d/"
erb $basedir/conf/php/php-pgsql.ini.erb > ${php_conf_dir}/php-pgsql.ini
erb $basedir/conf/php/php-redis-session.ini.erb > ${php_conf_dir}/php-redis-session.ini
erb $basedir/conf/php/php-opcache.ini.erb > ${php_conf_dir}/php-opcache.ini
erb $basedir/conf/php/php-apcu.ini.erb > ${php_conf_dir}/php-apcu.ini

#
# init nginx config
#
echo "# Init nginx nextcloud config"
erb conf/nginx/nextcloud.conf.erb > conf/nginx/nextcloud.conf
export NGINX_HTTP_INCLUDES="conf/nginx/nextcloud.conf"
