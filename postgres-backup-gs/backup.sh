#! /bin/sh

set -e
set -o pipefail

if [ "${GS_BUCKET}" = "**None**" ]; then
  echo "You need to set the GS_BUCKET environment variable."
  exit 1
fi

if [ "${POSTGRES_DATABASE}" = "**None**" ]; then
  echo "You need to set the POSTGRES_DATABASE environment variable."
  exit 1
fi

if [ "${POSTGRES_HOST}" = "**None**" ]; then
  if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
    POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    echo "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

if [ "${POSTGRES_USER}" = "**None**" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "**None**" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable or link to a container named POSTGRES."
  exit 1
fi

# Nasty! alpine does not play well with ndots.
cp /etc/resolv.conf /tmp/resolv.conf.orig
sed 's/^\(options ndots.*\)/#\1/g' /tmp/resolv.conf.orig > /etc/resolv.conf

if [ -n "${GS_SERVICE_KEY_FILE}" ]; then
  gcloud auth activate-service-account --key-file ${GS_SERVICE_KEY_FILE}
fi

export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS"

echo "Creating dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..."

pg_dump $POSTGRES_HOST_OPTS $POSTGRES_DATABASE | gzip > dump.sql.gz

echo "Uploading dump to $GS_BUCKET"

gsutil cp dump.sql.gz gs://$GS_BUCKET/$GS_PREFIX/$(date +"%Y-%m-%dT%H:%M:%SZ").sql.gz || exit 2

echo "SQL backup uploaded successfully"

if [ "${SLEEP}" == "yes" ]; then
	echo "Sleeping"
	tail -f /dev/null
fi
