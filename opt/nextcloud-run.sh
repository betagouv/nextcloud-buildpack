#!/bin/bash
#
if [ -n "$DEBUG" ]; then
  set -x
fi

#
# init nextcloud config
#
echo "# Init nextcloud"
bin/nextcloud-config.sh

#
# start php+nginx script (from https://github.com/Scalingo/php-buildpack/blob/master/bin/compile)
#
export NGINX_HTTP_INCLUDES="conf/nginx/nextcloud.conf"
echo "# Start nginx+php"
bin/run
