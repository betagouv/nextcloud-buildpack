#!/bin/bash
#
# init and configure nextcloud instance at runtime
#
set -o pipefail

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
if [[ -z "$NC_ADMIN_USER" ]]; then
  echo >&2 "The environment variable NC_ADMIN_USER must be set"
  exit -1
fi
if [[ -z "$NC_ADMIN_PASSWORD" ]]; then
  echo >&2 "The environment variable NC_ADMIN_PASSWORD must be set"
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

echo "# Installing with PostgreSQL database"

echo "# reset ${NC_ADMIN_USER} account"
( set +e
  DB_NC_IS_INSTALLED=$(psql $DATABASE_URL -qAt -c "SELECT true as exists FROM information_schema.tables WHERE table_type='BASE TABLE' AND table_schema='public'  AND table_name='oc_users';")
  if [[ -n "${DB_NC_IS_INSTALLED}" ]] ; then
    psql $DATABASE_URL -c "DELETE FROM oc_users WHERE uid='${NC_ADMIN_USER}'" || true
  fi
)
#
# first configuration
#
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

echo "# cleanup config template"
for c in $NC_CONFIG_TEMPLATE; do
  rm -rf config/$c.config.php
done

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

# configure app theme
echo "Setting login page"
php occ theming:config name "${NC_THEMING_CONFIG_NAME:-Beta}"
php occ theming:config url "${NC_THEMING_CONFIG_URL:-www.google.fr}"
php occ theming:config slogan "${NC_THEMING_CONFIG_SLOGAN:-Have fun !}"
php occ theming:config disable-user-theming "${NC_THEMING_CONFIG_DISABLE_USER:-yes}"
[[ -n "${NC_THEMING_CONFIG_LOGO}" ]] && php occ theming:config logo "${NC_THEMING_CONFIG_LOGO}"

#
# app
#
if [[ -z "$NC_APP_DISABLE" ]]; then
  NC_APP_DISABLE="federation
  nextcloud_announcements
  survey_client
  user_ldap
  weather_status"
fi

for app in ${NC_APP_DISABLE}; do
  php occ app:disable $app
done

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

if php occ config:system:get installed; then
  echo "# config.php"
  cat config/config.php
  echo "# config:list"
  php occ config:list
  echo "# app:list"
  php occ app:list
  echo "# status"
  php occ status --output=json
fi

echo "# ls data"
ls -l $(pwd)/data
)

echo "# prepare includes php ini"
php_conf_dir="vendor/php/etc/conf.d/"
erb $basedir/conf/php/php-pgsql.ini.erb > ${php_conf_dir}/php-pgsql.ini
erb $basedir/conf/php/php-redis-session.ini.erb > ${php_conf_dir}/php-redis-session.ini
erb $basedir/conf/php/php-opcache.ini.erb > ${php_conf_dir}/php-opcache.ini
erb $basedir/conf/php/php-apcu.ini.erb > ${php_conf_dir}/php-apcu.ini
echo "# End init"
