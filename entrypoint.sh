#!/usr/bin/env bash

set -e

EXTRA_ARGS=""
if [ -n "${2}" ]; then
   EXTRA_ARGS=" --application=${2}"
fi

if [ -n "${3}" ]; then
   EXTRA_ARGS="${EXTRA_ARGS} --add-context=${3}"
fi

if [ -n "${4}" ]
then
   EXTRA_ARGS="${EXTRA_ARGS} --with-scm-file=${4}"
else
   EXTRA_ARGS="${EXTRA_ARGS} --with-scm"
fi

if [ "${5,,}" = "true" ]; then
  EXTRA_ARGS="${EXTRA_ARGS} --watch"
fi

armory version
armory deploy start ${EXTRA_ARGS} --file "${1}" --with-scm

