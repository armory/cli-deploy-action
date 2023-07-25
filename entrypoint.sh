#!/usr/bin/env bash
set -e

GH_KEYS=("GITHUB_REPOSITORY" "GITHUB_ACTOR" "GITHUB_TRIGGERING_ACTOR" "GITHUB_REF" "GITHUB_REF_NAME" "GITHUB_REF_TYPE" "GITHUB_HEAD_REF" "GITHUB_EVENT_NAME" "GITHUB_REPOSITORY_URL" "GITHUB_RUN_ID" "GITHUB_SHA")

for VAR in "${GH_KEYS[@]}"; do
  ARGS+=("$VAR=${!VAR}")
done
LINEAGE=$(IFS=, ; echo "${ARGS[*]}")

# Validate authorization for gh
GH_STATUS=true

if [ -z "$GH_TOKEN" ]; then
  echo "INFO: The GH_TOKEN is empty, this action will be unable to retrieve the title of PR's"
  GH_STATUS=false
else
  gh auth status &>/dev/null || GH_STATUS=false
  if [ "$GH_STATUS" = "false" ];then
    echo "INFO: The GH_TOKEN is invalid, this action will be unable to retrieve the title of PR's"
  fi
fi

if [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
  PR_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY${GITHUB_REF:4}"
  if [ "$GH_STATUS" = "true" ]; then
    PR_TITLE=`gh pr view $PR_URL --json title --jq .title | base64 || echo ""`
  fi
  LINEAGE="$LINEAGE,PR_URL=$PR_URL,PR_TITLE=$PR_TITLE"
fi

if [ "$GITHUB_EVENT_NAME" = "push" ]; then
  if [ "$GH_STATUS" = "true" ]; then
    PR=`gh pr list --search "$GITHUB_SHA" --state merged --json number --jq ".[].number"`
    PR_URL="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/pull/${PR[0]}/merge"
    PR_TITLE=`gh pr view $PR_URL --json title --jq .title | base64 || echo ""`
  fi
  LINEAGE="$LINEAGE,PR_URL=$PR_URL,PR_TITLE=$PR_TITLE"
fi

EXTRA_ARGS=""
if [ -n "${2}" ]; then
  EXTRA_ARGS=" --application=${2}"
fi

EXTRA_ARGS="$EXTRA_ARGS --add-context=$LINEAGE"
if [ -n "${3}" ]; then
  EXTRA_ARGS="${EXTRA_ARGS},${3}"
fi

if [ "${4,,}" = "true" ]; then
  EXTRA_ARGS="${EXTRA_ARGS} --watch"
fi

armory version
armory deploy start --file "${1}" ${EXTRA_ARGS}