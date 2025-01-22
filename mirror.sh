#!/usr/bin/env bash
set -eu

source_repo="cider-org/ktlint"
target_repo="cider-org/cider-ai"
github_server_url="https://github.com"
github_api_url="$github_server_url/api/v3"
github_url="https://token:$TOKEN_FOR_GITHUB_COM@$github_server_url"
max_repos=1

echo "github_url $github_url"

[[ -f .env ]] && source .env

if [ -z "$TOKEN_FOR_GITHUB_COM" ]; then
  echo "TOKEN_FOR_GITHUB_COM env needed"
  exit 1
fi

function set-default-branch {
  repo=$1
  branch="main"
  echo "     set default branch to '$branch'"
  response=$(curl -sS -u token:$TOKEN_FOR_GITHUB_COM \
    -X PATCH "$github_api_url/repos/$repo" \
    --data '{"default_branch": "'$branch'", "has_issues": false, "has_wiki": false}')

  if echo $response | grep -q "Validation Failed"; then
    echo $response
  fi

  # we ignore failure to set the default branch, e.g. empty repo with no commit
  return 0
}

function repo-failed {
  repo=$1
  log=$2
  echo "::error file=mirror.list::failed to mirror $repo - $log"
}

echo $TOKEN_FOR_GITHUB_COM | gh auth login --with-token

repo=$source_repo
org_and_name=$(echo "$repo" | awk -F"/" '{ print $1"-"$2 }')
log="/tmp/log.$org_and_name"

(
  org=$(echo "$repo" | awk -F"/" '{ print $1 }')
  name=$(echo "$repo" | awk -F"/" '{ print $2 }')
  # Ensure tmp directory is deleted
  rm -rf "/tmp/$org_and_name"

  # prepare logfile
  echo "" > $log
  echo "mirror $repo -> $github_server_url/$target_repo" | tee -a $log

  # Pull newest changes
  echo "Cloning repository $repo" | tee -a $log
  if ! git clone --mirror "https://token:$TOKEN_FOR_GITHUB_COM@github.com/$org/$name.git" "/tmp/$org_and_name" &>> $log; then
    echo "Error cloning repository $repo" | tee -a $log
    repo-failed "$repo" "$(cat $log)"
    exit 1
  fi
  echo "     cloned" | tee -a $log
  cd "/tmp/$org_and_name"

  # remove refs/pull as they can't be pushed
  echo "Removing refs/pull" | tee -a $log
  if ! git for-each-ref --format 'delete %(refname)' refs/pull | git update-ref --stdin &>> $log; then
    echo "Error removing refs/pull" | tee -a $log
    repo-failed "$repo" "$(cat $log)"
    exit 1
  fi
  echo "     refs/pull removed" | tee -a $log

  # Remove unwanted files
  echo "Removing unwanted files" | tee -a $log
  git filter-repo --path .github/workflows --invert-paths &>> $log
  git filter-repo --path mirror.sh --invert-paths &>> $log
  echo "     unwanted files removed" | tee -a $log

  # Push everything to the target repository
  echo "Pushing to target repository $target_repo" | tee -a $log
  if ! git -c http.version=HTTP/1.1 push --mirror --force --prune "$github_url/$target_repo" &>> $log; then
    echo "Error pushing to target repository $target_repo" | tee -a $log
    repo-failed "$repo" "$(cat $log)"
    exit 1
  fi
  echo "     pushed" | tee -a $log

  set-default-branch "$target_repo"
) || repo-failed "$repo" "$(cat $log)"
