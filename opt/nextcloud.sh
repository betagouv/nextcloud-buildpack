#!/bin/bash
#
if [ -n "$DEBUG" ]; then
  set -x
fi
#
# init nextcloud config
#
echo "# Init nextcloud"
bin/nextcloud-init.sh
#
# init htpasswd for basic auth
#
echo $NGINX_USER:$NGINX_PASSWORD > conf/htpasswd
#
# init nginx config
#
echo "# Init nginx nextcloud config"
erb conf/nginx/nextcloud.conf.erb > conf/nginx/nextcloud.conf
export NGINX_HTTP_INCLUDES="conf/nginx/nextcloud.conf"
#
# start php+nginx script (from https://github.com/Scalingo/php-buildpack/blob/master/bin/compile)
#
echo "# Start nginx+php"
bin/run
