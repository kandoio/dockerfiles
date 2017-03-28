#! /bin/sh

# exit if a command fails
set -e

# install pg_dump
apk add --no-cache postgresql

# install gcloud sdk
apk add --no-cache bash curl ca-certificates python
export CLOUDSDK_CORE_DISABLE_PROMPTS=1
curl https://sdk.cloud.google.com | bash

apk del bash curl ca-certificates
