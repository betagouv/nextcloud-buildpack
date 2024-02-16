basedir="/app"

if [ -n "$DEBUG" ]; then
  set -x
fi

echo "# Init nextcloud"

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
export NC_CONFIG_TEMPLATE="base secret s3 redis smtp oidc"
for c in $NC_CONFIG_TEMPLATE; do
  echo "# $c.config.php"
  [ -f "$basedir/conf/nextcloud/$c.config.php" ] && cp $basedir/conf/nextcloud/$c.config.php config/$c.config.php
done

php occ  maintenance:install \
  --database=pgsql \
  --database-name=${DATABASE_NAME} \
  --database-host=${DATABASE_HOST} \
  --database-port=${DATABASE_PORT} \
  --database-user=${DATABASE_USER} \
  --database-pass=${DATABASE_PASS} \
  --admin-user=${NC_ADMIN_USER} \
  --admin-pass=${NC_ADMIN_PASSWORD} \
  --admin-email=${NC_ADMIN_EMAIL} \
  --no-ansi \
  -n

echo "# ls data"
ls -l $(pwd)/data
fi )

#
# import config set
#
( set -e

  NC_CONFIG_FILE="$basedir/conf/nextcloud/nextcloud_config.json"

  #
  # override NC_CONFIG_FILE if NC_CONFIG_JSON_BASE64 exist
  #
  if [[ -n "${NC_CONFIG_JSON_BASE64}" ]] ; then
     echo "## import config from NC_CONFIG_JSON_BASE64"
     mkdir -p $(dirname $NC_CONFIG_FILE)
     echo "${NC_CONFIG_JSON_BASE64}" |base64 -d > $NC_CONFIG_FILE
  fi
  #
  # import nextcloud config
  #
  if [[ -f "${NC_CONFIG_FILE}" ]] ; then
   echo "## import config from nextcloud_config.json"
   php occ config:import "${NC_CONFIG_FILE}"
  fi
) || exit $?

fi


echo "# prepare includes php ini"
php_conf_dir="vendor/php/etc/conf.d/"
erb $basedir/conf/php/php-pgsql.ini.erb > ${php_conf_dir}/php-pgsql.ini
erb $basedir/conf/php/php-redis-session.ini.erb > ${php_conf_dir}/php-redis-session.ini
erb $basedir/conf/php/php-opcache.ini.erb > ${php_conf_dir}/php-opcache.ini
erb $basedir/conf/php/php-apcu.ini.erb > ${php_conf_dir}/php-apcu.ini
echo "# End init"


