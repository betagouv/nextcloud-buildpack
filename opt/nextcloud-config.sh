#!/bin/bash
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
export NC_CONFIG_TEMPLATE="base secret s3 redis smtp oidc db"
for c in $NC_CONFIG_TEMPLATE; do
  echo "# $c.config.php"
  [ -f "$basedir/conf/nextcloud/$c.config.php" ] && cp $basedir/conf/nextcloud/$c.config.php config/$c.config.php
done
fi
)

cd $basedir/nextcloud
#
# app
#
if [[ -z "$NC_APP_ENABLE" ]]; then
  NC_APP_ENABLE="files_external"
fi

for app in ${NC_APP_ENABLE}; do
  php occ app:enable $app
done

php occ upgrade
