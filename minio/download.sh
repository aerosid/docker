#!/bin/bash

URL=127.0.0.1:9000
USERNAME=minio-root-user
PASSWORD=minio-root-password
BUCKET=tmp
MINIO_PATH="/${BUCKET}/message.txt"
OUT_FILE=/tmp/message.bak.txt

DATE=$(date -R --utc)
CONTENT_TYPE='application/zstd'
SIG_STRING="GET\n\n${CONTENT_TYPE}\n${DATE}\n${MINIO_PATH}"
SIGNATURE=`echo -en ${SIG_STRING} | openssl sha1 -hmac ${PASSWORD} -binary | base64`

curl -o "${OUT_FILE}" \
-H "Host: $URL" \
-H "Date: ${DATE}" \
-H "Content-Type: ${CONTENT_TYPE}" \
-H "Authorization: AWS ${USERNAME}:${SIGNATURE}" \
http://$URL${MINIO_PATH}
