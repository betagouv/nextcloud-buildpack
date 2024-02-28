#!/bin/bash
#
if [ -n "$DEBUG" ]; then
  set -x
fi

#
# init nextcloud config
#
echo "# Init nextcloud"
bin/nextcloud-run.sh


php -f nextcloud/cron.php