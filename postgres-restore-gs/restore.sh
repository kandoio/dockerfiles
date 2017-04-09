#! /bin/sh

set -e
set -o pipefail

if [ -n "${GS_SERVICE_KEY_FILE}" ]; then
  gcloud auth activate-service-account --key-file ${GS_SERVICE_KEY_FILE}
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

export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER"

if [ -z "${BACKUP}" ]; then
	echo "Finding latest backup"
	BACKUP=$(gsutil ls gs://$GS_BUCKET/$GS_PREFIX/ | sort | tail -n 1)
fi

echo "Fetching ${BACKUP} from GS"

gsutil cp ${BACKUP} dump.sql.gz
gzip -d dump.sql.gz

echo "Waiting for DB to be available"

NEXT_WAIT_TIME=0
NUMBER_OF_WAITS=10
WAIT_CMD="psql $POSTGRES_HOST_OPTS -d $POSTGRES_DATABASE -c \"select 'It is running'\" | grep 'It is running'"
until eval "${WAIT_CMD}" || [ ${NEXT_WAIT_TIME} -eq ${NUMBER_OF_WAITS} ]; do
	sleep $(( NEXT_WAIT_TIME++ ))
done
eval ${WAIT_CMD}

if [ "${DROP_PUBLIC}" == "yes" ]; then
	echo "Recreating the public schema"
	psql $POSTGRES_HOST_OPTS -d $POSTGRES_DATABASE -c "drop schema if exists public cascade; create schema public;"
fi

if [ "${DROP_PUBLIC_TABLES}" == "yes" ]; then
        echo "Dropping the public tables"
	sql=$(psql $POSTGRES_HOST_OPTS -d $POSTGRES_DATABASE -P "tuples_only" -c "select 'drop table if exists \"' || tablename || '\" cascade;' from pg_tables where schemaname = 'public';")
	psql $POSTGRES_HOST_OPTS -d $POSTGRES_DATABASE -c "${sql}"
fi

echo "Restoring ${LATEST_BACKUP}"

psql $POSTGRES_HOST_OPTS -d $POSTGRES_DATABASE < dump.sql

echo "Restore complete"

if [ "${SLEEP}" == "yes" ]; then
	echo "Sleeping"
	tail -f /dev/null
fi
