# nextcloud-buildpack
A buildpack for Nextcloud's deployment to Scalingo


## envionment

Create a repo `my-nextcloud-app` with following files
- `.buildpack`
```
https://github.com/pli01/nextcloud-buildpack#feat-install
https://github.com/Scalingo/php-buildpack
```

- Add custom configuration, with a file `nextconfig_config.json` (copy `nextcloud_config.json.sample`)

This config is minimal and for testing purpose: appstore is disabled, no skeleton, no update checker, and disable all apps

```json
{
  "system": {
    "default_language": "fr",
    "default_locale": "fr",
    "default_phone_region": "FR",
    "skeletondirectory": "",
    "templatedirectory": "",
    "appstoreenabled": false,
    "appstoreurl": "",
    "updatechecker": false
  },
  "apps": {
    "activity": {
      "enabled": "no"
    }
  }
}
```

- Other customisation:
  - Add logo in `nextcloud/core/img/logo/mylogo.png`
  - create theme 

- in scalingo app, define your env file
```bash
#
# default admin user
#
NC_ADMIN_USER=_REPLACE_ADMIN_USER_
NC_ADMIN_PASSWORD=_REPLACE_ADMIN_PASSWORD_
NC_ADMIN_EMAIL=user@domain.com
#
# default passwordsalt
#
NC_CONFIG_PASSWORDSALT="_REPLACE_"
#
# default secret
#
NC_CONFIG_SECRET="_REPLACE_"
#
# Trusted domain
#
NC_TRUSTED_DOMAINS="mydomain.com myother.com"
#
# Primary Storage S3
#
OBJECTSTORE_S3_SSL=true
OBJECTSTORE_S3_KEY=_REPLACE_
OBJECTSTORE_S3_BUCKET=_REPLACE_
OBJECTSTORE_S3_HOST=s3.gra.io.cloud.ovh.net
OBJECTSTORE_S3_REGION=gra
OBJECTSTORE_S3_SECRET=_REPLACE_
OBJECTSTORE_S3_AUTOCREATE=true
#
# Theming (login page)
#
NC_THEMING_CONFIG_NAME="Sample"
NC_THEMING_CONFIG_SLOGAN="it works!"
NC_THEMING_CONFIG_URL="github.com"
NC_THEMING_CONFIG_LOGO="/app/nextcloud/core/img/logo/mylogo.png"
#
# (option)
#
NC_CONFIG_JSON_BASE64 : encoded base64 nextcloud_config.json (replace the default nextcloud_config.json)


```

Add addons:
 - postgresql postgresql-starter-1024
 - redis redis-starter-512

## Tips and Docs

- config: https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/config_sample_php_parameters.html
- occ command: https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html
- nginx configuration: https://docs.nextcloud.com/server/latest/admin_manual/installation/nginx.html#nextcloud-in-the-webroot-of-nginx
- primary storage S3: https://docs.nextcloud.com/server/24/admin_manual/configuration_files/primary_storage.html#simple-storage-service-s3
- scale S3 bucket: https://docs.nextcloud.com/server/24/admin_manual/configuration_files/primary_storage.html#multibucket-object-store

