#!/usr/bin/env sh

set -e

EXTRA_ARGS=""
if [ -n "${2}" ]; then
   EXTRA_ARGS=" --application=${2}"
fi

if [ -n "${3}" ]; then
   EXTRA_ARGS="${EXTRA_ARGS} --add-context=${3}"
fi

armory version
armory deploy start ${EXTRA_ARGS} --file "${1}"

