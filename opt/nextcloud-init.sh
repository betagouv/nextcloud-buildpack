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

if [[ -z "$SCALINGO_POSTGRESQL_URL" ]]; then
  echo >&2 "The environment variable SCALINGO_POSTGRESQL_URL must be set. The default user should be updated with the CREATEROLE privilege."
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

# Following regex is based on https://www.rfc-editor.org/rfc/rfc3986#appendix-B with
# additional sub-expressions to split authority into userinfo, host and port
#
URI_REGEX='^(postgres?:\/\/)((.*):(.*)@)?([^:\/?#]+)(:([0-9]+))?(\/([^?#]*))(\?([^#]*))?(#(.*))?'

parse_scheme () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[1]}"
}

parse_authority () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[2]}"
}

parse_user () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[3]}"
}

parse_pass () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[4]}"
}

parse_host () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[5]}"
}

parse_port () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[7]}"
}

parse_path () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[8]}"
}

parse_rpath () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[9]}"
}

parse_query () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[10]}"
}

parse_fragment () {
    [[ "$@" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[11]}"
}


eval "DATABASE_USER=$(parse_user $DATABASE_URL)"
eval "DATABASE_PASS=$(parse_pass $DATABASE_URL)"
eval "DATABASE_HOST=$(parse_host $DATABASE_URL)"
eval "DATABASE_PORT=$(parse_port $DATABASE_URL)"
eval "DATABASE_NAME=$(parse_rpath $DATABASE_URL)"

export DATABASE_USER
export DATABASE_PASS
export DATABASE_HOST
export DATABASE_PORT
export DATABASE_NAME

( cd nextcloud
#
# is installed ?
#
if [[ ! -f config/config.php ]] ; then

echo "# prepare config template"
cp $basedir/conf/s3.config.php config/s3.config.php

echo "# Installing with PostgreSQL database"

echo "# reset ${NC_ADMIN_USER} account"
psql $DATABASE_URL -c "DELETE FROM oc_users  WHERE uid='${NC_ADMIN_USER}'"
#
# configure
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
rm conf/s3.config.php

export OC_PASS=$NC_ADMIN_PASSWORD
php occ user:resetpassword ${NC_ADMIN_USER} --password-from-env
#
# import config set
#
( set -e

  NC_CONFIG_FILE="$basedir/nextcloud_config.json"
  
  #
  # override NC_CONFIG_FILE if NC_CONFIG_JSON_BASE64 exist
  #
  if [[ -n "${NC_CONFIG_JSON_BASE64}" ]] ; then
     echo "${NC_CONFIG_JSON_BASE64}" |base64 -d > $NC_CONFIG_FILE
  fi
  #
  # import nextcloud config
  #
  if [[ -f "${NC_CONFIG_FILE}" ]] ; then
   php occ config:import "${NC_CONFIG_FILE}"
   rm -rf "${NC_CONFIG_FILE}"
  fi
) || exit $?

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
php occ theming:config name "${NC_THEMING_CONFIG_NAME:-Beta}"
php occ theming:config url "${NC_THEMING_CONFIG_URL:-www.google.fr}"
php occ theming:config slogan "${NC_THEMING_CONFIG_SLOGAN:-Have fun !}"
php occ theming:config disable-user-theming "${NC_THEMING_CONFIG_DISABLE_USER:yes}"
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

fi

if php occ config:system:get installed; then
  echo "# config:list"
  php occ config:list
  echo "# app:list"
  php occ app:list
  echo "# status"
  php occ status --output=json
fi

)
