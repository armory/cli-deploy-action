#!/usr/bin/env bash

set -e

EXTRA_ARGS=" --add-context=actor=$GITHUB_ACTOR"
if [ -n "${2}" ]; then
   EXTRA_ARGS=" --application=${2}"
fi

# if [ -n "${3}" ]; then
#    EXTRA_ARGS="${EXTRA_ARGS} --add-context=${3}"
# fi

if [ "${4,,}" = "true" ]; then
  EXTRA_ARGS="${EXTRA_ARGS} --watch"
fi

armory version
armory deploy start ${EXTRA_ARGS} --file "${1}"

