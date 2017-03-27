#! /bin/sh

# exit if a command fails
set -e

# install pg_dump
apk add --no-cache 'postgresql>9.5.0'

# install gcloud sdk
apk add --no-cache bash curl ca-certificates python
export CLOUDSDK_CORE_DISABLE_PROMPTS=1
curl https://sdk.cloud.google.com | bash

# install go-cron
curl -L --insecure https://github.com/odise/go-cron/releases/download/v0.0.6/go-cron-linux.gz | zcat > /usr/local/bin/go-cron
chmod u+x /usr/local/bin/go-cron

apk del bash curl ca-certificates
