all: up
build: config buildpack-archive
	docker-compose build
buildpack-archive:
	( cd .. ;  git archive --format tar.gz main ) > buildpack.tar.gz
up: config
	docker-compose up -d
config:
	docker-compose config

clean-all: down clean-dir
down:
	docker-compose down

clean-dir:
	rm -rf postgresql redis s3
