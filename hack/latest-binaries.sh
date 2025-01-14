#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

if [ "$#" -ne 1 ]; then
  echo "usage: $0 KUBERNETES_MINOR_VERSION"
  exit 1
fi

MINOR_VERSION="${1}"

# retrieve the available "VERSION/BUILD_DATE" prefixes (e.g. "1.28.1/2023-09-14")
# from the binary object keys, sorted in descending semver order, and pick the first one
# If s3api fails; use curl to pull the list. For some reason, reversing order returns nothing, so I dropped that from the sort command
LATEST_BINARIES=$(aws s3api list-objects-v2 --bucket amazon-eks --prefix "${MINOR_VERSION}" --query 'Contents[*].[Key]' --output text | cut -d'/' -f-2 | sort -Vru | head -n1 || curl -s  "https://amazon-eks.s3.amazonaws.com/?prefix=${MINOR_VERSION}" | xmllint --format  --nocdata - | grep -E  "<Key>${MINOR_VERSION}.*" | sed "s/^.*<Key>//g" | sort -Vu | tail -n 1)
	
if [ "${LATEST_BINARIES}" == "None" ]; then
  echo >&2 "No binaries available for minor version: ${MINOR_VERSION}"
  exit 1
fi

LATEST_VERSION=$(echo "${LATEST_BINARIES}" | cut -d'/' -f1)
LATEST_BUILD_DATE=$(echo "${LATEST_BINARIES}" | cut -d'/' -f2)

echo "kubernetes_version=${LATEST_VERSION} kubernetes_build_date=${LATEST_BUILD_DATE}"
