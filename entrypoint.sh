#!/bin/bash

set -o pipefail

apt-get update
apt-get install -y curl

curl https://dl.min.io/client/mc/release/linux-amd64/mc \
    --create-dirs \
    -o $HOME/minio-binaries/mc

chmod +x $HOME/minio-binaries/mc
export PATH=$PATH:$HOME/minio-binaries/

STORAGE_SERVICE_ALIAS=${STORAGE_SERVICE_ALIAS:="s3"}
STORAGE_SERVICE_URL=${STORAGE_SERVICE_URL:="https://s3.amazonaws.com"}
FILENAME="dump_$(date +%Y%m%d%H%M%S)"
ACCESS_KEY_ID=${ACCESS_KEY_ID:=""}
SECRET_ACCESS_KEY=${SECRET_ACCESS_KEY:=""}
AWS_BUCKET=${AWS_BUCKET:=""}
MONGODB_URI=${MONGODB_URI:=""}

mc alias set "$STORAGE_SERVICE_ALIAS" "$STORAGE_SERVICE_URL" "$ACCESS_KEY_ID" "$SECRET_ACCESS_KEY"

# Execute mc pipe mongodump output to s3 bucket and check for failure
mongodump --archive --gzip --uri=$MONGODB_URI | mc pipe "$STORAGE_SERVICE_ALIAS/$AWS_BUCKET/$FILENAME"
MONGODUMP_STATUS=$?

if [ $MONGODUMP_STATUS -ne 0 ]; then
  echo "Mongodump failed with status $MONGODUMP_STATUS"
  exit $MONGODUMP_STATUS
fi
