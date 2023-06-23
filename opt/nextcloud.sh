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
# init nginx nextcloud config
#
echo "# Init nginx nextcloud config"
erb conf/nextcloud.conf.erb > conf/nextcloud.conf
export NGINX_HTTP_INCLUDES="conf/nextcloud.conf"
#
# start php+nginx script (from https://github.com/Scalingo/php-buildpack/blob/master/bin/compile)
#
echo "# Start nginx+php"
bin/run
