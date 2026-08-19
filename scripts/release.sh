#!/usr/bin/env bash
# Build (and optionally upload) a Sakinah release for a chosen stage.
#
# Usage:
#   scripts/release.sh                     # interactive stage picker, builds + uploads
#   scripts/release.sh production          # builds + uploads to Play Console
#   scripts/release.sh staging --build-only  # builds the AAB only, no upload
#
# Env vars:
#   PLAY_STORE_JSON_KEY_PATH   Path to the Play Console service account JSON key.
#                              Required unless --build-only is passed.
#   RELEASE_STATUS             Overrides the default release_status (draft/completed/
#                              inProgress/halted) passed to Play Console.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

STAGE="${1:-}"
BUILD_ONLY=false
for arg in "$@"; do
  if [[ "$arg" == "--build-only" ]]; then
    BUILD_ONLY=true
  fi
done

if [[ -z "$STAGE" || "$STAGE" == "--build-only" ]]; then
  echo "Select a stage to release:"
  select STAGE in dev staging production; do
    [[ -n "$STAGE" ]] && break
  done
fi

case "$STAGE" in
  dev|staging|production) ;;
  *)
    echo "Error: stage must be one of: dev, staging, production" >&2
    exit 1
    ;;
esac

if [[ "$BUILD_ONLY" == false && -z "${PLAY_STORE_JSON_KEY_PATH:-}" ]]; then
  echo "Error: PLAY_STORE_JSON_KEY_PATH is not set." >&2
  echo "Export it to your Play Console service account JSON key path, or pass --build-only to just build the AAB." >&2
  exit 1
fi

if [[ "$BUILD_ONLY" == false && ! -f "${PLAY_STORE_JSON_KEY_PATH:-}" ]]; then
  echo "Error: PLAY_STORE_JSON_KEY_PATH points to a file that doesn't exist: $PLAY_STORE_JSON_KEY_PATH" >&2
  exit 1
fi

cd "$REPO_ROOT/android"
bundle check >/dev/null 2>&1 || bundle install

if [[ "$BUILD_ONLY" == true ]]; then
  echo "Building '$STAGE' release AAB (no upload)..."
  bundle exec fastlane build stage:"$STAGE"
else
  echo "Building and uploading '$STAGE' release to Google Play..."
  RELEASE_STATUS_ARG=()
  if [[ -n "${RELEASE_STATUS:-}" ]]; then
    RELEASE_STATUS_ARG=(release_status:"$RELEASE_STATUS")
  fi
  bundle exec fastlane deploy stage:"$STAGE" "${RELEASE_STATUS_ARG[@]}"
fi
