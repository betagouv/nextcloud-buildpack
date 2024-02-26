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

php -d memory_limit=512M nextcloud/cron.php