#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

DSYM_DIR="${ARCHIVE_PATH}/dSYMs"

if [ -z "${POSTHOG_PERSONAL_API_KEY:-}" ]; then
    log_item "Skipping PostHog dSYM upload (POSTHOG_PERSONAL_API_KEY not set)"
    exit 0
fi

if [ ! -d "$DSYM_DIR" ]; then
    log_warn "Skipping PostHog dSYM upload (no dSYMs found at ${DSYM_DIR})"
    exit 0
fi

log_warn "PostHog dSYM upload is not configured yet"
log_item "dSYMs are available at: ${DSYM_DIR}"
log_item "Upload them using the official PostHog dSYM upload flow for error tracking."
