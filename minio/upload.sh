#!/bin/bash

URL=127.0.0.1:9000
USERNAME=minio-root-user
PASSWORD=minio-root-password
BUCKET=tmp
FILE=/tmp/message.txt
FILE_NAME=message.txt
OBJ_PATH="/${BUCKET}/${FILE_NAME}"

# Static Vars
DATE=$(date -R --utc)
CONTENT_TYPE='application/zstd'
SIG_STRING="PUT\n\n${CONTENT_TYPE}\n${DATE}\n${OBJ_PATH}"
SIGNATURE=`echo -en ${SIG_STRING} | openssl sha1 -hmac ${PASSWORD} -binary | base64`

curl --silent -v -X PUT -T "${FILE}" \
-H "Host: $URL" \
-H "Date: ${DATE}" \
-H "Content-Type: ${CONTENT_TYPE}" \
-H "Authorization: AWS ${USERNAME}:${SIGNATURE}" \
http://$URL${OBJ_PATH}
