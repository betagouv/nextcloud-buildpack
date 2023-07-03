# docker-compose scalingo stack for development steps

This stack build a local dev environement

It use the following docker image:
- scalingo redis:  https://hub.docker.com/r/scalingo/redis
- postgres
- smtp: mailhog
- s3: minio
- Your nextcloud scalingo image (build from local or pull from scalingo)

redis, postgres and s3 data files are stored under this directory

## Steps:
- Option 1: To build your own local dev docker image

This steps, build a git archive from your source repo and build image with docker

```bash
make build
```

- Option 2: To use docker image built from Scalingo
In your scalingo app:
  - enable the docker addons in scalingo app
  - build the nextcloud app docker image
  - docker pull your_nextcloud_app (https://doc.scalingo.com/addons/scalingo-docker-image/start)
  - add in .env , the variable `SCALINGO_NEXTCLOUD_IMAGE=registry-xxxx/YOUR_APP/BUILD_ID`

- Create dev `.env` file, with custom parameters

```bash
# only for dev purpose
UID=501 # your uid
SCALINGO_NEXTCLOUD_IMAGE=registry-3-osc-fr1.scalingo.com/${_YOUR_NEXTCLOUD_ALL_}:${_YOUR_NEXTCLOUD_BUILD_ID_}
REDIS_PASSWORD=password
DB_USER=nextcloud
DB_PASSWORD=nextcloud_password
NC_TRUSTED_DOMAINS=localhost
NC_ADMIN_EMAIL=test@domain.com
NC_ADMIN_PASSWORD=_REPLACE_
NC_ADMIN_USER=admin
# add other config
```

You can use quick make:
```bash
# to start the stack
make
```
- Connect to http://localhost and play

```bash
# to stop the stack
make down
# to clean all
make clean-all
```

Or use docker-compose cli
- Start the docker-compose stack
```bash
docker-compose up -d
docker-compose logs
```

- To stop and clean all
```bash
docker-compose down
# rm -rf postgresql redis s3
```

## Dev Url

- nextcloud: http://localhost
- s3 minio console: http://localhost:9001
- mailhog: http://localhost:8025
