#!/bin/sh

set -euo pipefail

export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY
export AWS_DEFAULT_REGION=$AWS_S3_REGION

DATE=$(date +%Y-%m-%d)
HOUR=$(date -d "-1 hour" +%H)

rds_download_logs () {
  aws rds download-db-log-file-portion --db-instance-identifier $INSTANCEID --starting-token 0 --output text --log-file-name error/postgresql.log.${DATE}-${HOUR} > ${PGBADGER_LOGS}/postgresql.log.${DATE}-${HOUR}
}

rds_clean_files () {
  rm -rf ${PGBADGER_LOGS}/*
}

upload_s3 () {
  aws s3 sync ${PGBADGER_DATA} 's3://'${AWS_S3_BUCKET}'/'${INSTANCEID}
}

run_pgbadger () {
  pgbadger --exclude-query="^(COPY|COMMIT)" -j ${JOBS} -I -O ${PGBADGER_DATA} -R ${RETENTION} ${PGBADGER_LOGS}/postgresql.log.${DATE}-${HOUR} -f stderr -p '%t:%r:%u@%d:[%p]:'
}

if [[ 1 == "${CRON}" ]]; then
  echo "run every"
  CRON_PATTERN=${CRON_PATTERN:-'0 1 * * *'}
  echo "run $CRON_PATTERN"
  echo "$CRON_PATTERN /entrypoint.sh" > /etc/crontabs/root
  export CRON=0
  crond -f
else
  echo "run one time"
  echo "Downloding log file"
  rds_download_logs
  echo 'Running pgBadger'
  run_pgbadger
  echo 'Upload report files'
  upload_s3
fi