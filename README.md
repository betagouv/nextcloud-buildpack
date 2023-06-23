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
NC_ADMIN_USER=_REPLACE_ADMIN_USER_
NC_ADMIN_PASSWORD=_REPLACE_ADMIN_PASSWORD_
NC_ADMIN_EMAIL=user@domain.com
# Trusted domain
NC_TRUSTED_DOMAINS="mydomain.com myother.com"
# Theming
NC_THEMING_CONFIG_NAME="Sample"
NC_THEMING_CONFIG_SLOGAN="it works!"
NC_THEMING_CONFIG_URL="github.com"
NC_THEMING_CONFIG_LOGO="/app/nextcloud/core/img/logo/mylogo.png"
```

Add addons:
 - postgresql postgresql-starter-1024

## Tips and Docs

- config: https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/config_sample_php_parameters.html
- occ command: https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html
- nginx configuration: https://docs.nextcloud.com/server/latest/admin_manual/installation/nginx.html#nextcloud-in-the-webroot-of-nginx
