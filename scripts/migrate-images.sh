#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 5 ]]; then
  echo "Usage: $0 <awsAccountId> <region> <repository> <tag> <acrName>"
  exit 1
fi

AWS_ACCOUNT_ID="$1"
REGION="$2"
REPO="$3"
TAG="$4"
ACR_NAME="$5"

ECR="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
ACR_LOGIN_SERVER="$(az acr show -n "${ACR_NAME}" --query loginServer -o tsv)"

echo "ECR: ${ECR}"
echo "ACR: ${ACR_LOGIN_SERVER}"

aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ECR}"
az acr login -n "${ACR_NAME}" >/dev/null

SRC="${ECR}/${REPO}:${TAG}"
DST="${ACR_LOGIN_SERVER}/${REPO}:${TAG}"

echo "Pull ${SRC}"
docker pull "${SRC}"

echo "Tag -> ${DST}"
docker tag "${SRC}" "${DST}"

echo "Push ${DST}"
docker push "${DST}"

echo "Done. Image at: ${DST}"
