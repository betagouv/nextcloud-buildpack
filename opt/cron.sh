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

php -f nextcloud/cron.php