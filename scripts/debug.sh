#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/config.sh"

SHOW_LOGS=false
VERIFY_PROCESS=false

for arg in "$@"; do
    case "$arg" in
        --logs)
            SHOW_LOGS=true
            ;;
        --verify)
            VERIFY_PROCESS=true
            ;;
        -h|--help)
            echo "Usage: $0 [--verify] [--logs]"
            echo ""
            echo "Builds the Debug app, stops any running ${PROJECT_NAME} process, and launches the fresh build."
            echo "  --verify  confirm the process is running after launch"
            echo "  --logs    stream unified logs for the launched app"
            exit 0
            ;;
        *)
            log_error "Unknown option: $arg"
            log_item "Usage: $0 [--verify] [--logs]"
            exit 1
            ;;
    esac
done

DEBUG_DERIVED_DATA="${BUILD_DIR}/DebugDerivedData"
DEBUG_APP_PATH="${DEBUG_DERIVED_DATA}/Build/Products/Debug/${PROJECT_NAME}.app"

print_header "${PROJECT_NAME} Debug Build & Launch" 55

print_step 1 3 "Building Debug App"
start_step_timer "debug-build"

mkdir -p "${BUILD_DIR}"

xcodebuild \
    -project "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration Debug \
    -derivedDataPath "${DEBUG_DERIVED_DATA}" \
    build \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    2>&1 | tee "${BUILD_DIR}/debug-build.log" | while read -r line; do
        if [[ "$line" == *"error:"* ]]; then
            echo -e "  ${RED}${SYM_CROSS} ${line}${NC}"
        elif [[ "$line" == *"warning:"* ]]; then
            echo -e "  ${YELLOW}${SYM_WARN} ${line}${NC}"
        elif [[ "$line" == "** BUILD SUCCEEDED **" ]]; then
            echo -e "  ${GREEN}${SYM_CHECK} Build succeeded${NC}"
        elif [[ "$line" == "** BUILD FAILED **" ]]; then
            echo -e "  ${RED}${SYM_CROSS} Build failed${NC}"
        fi
    done

if [ ! -d "${DEBUG_APP_PATH}" ]; then
    log_failure "Failed to find built app"
    log_item "Expected: ${DEBUG_APP_PATH}"
    log_item "Check ${BUILD_DIR}/debug-build.log"
    exit 1
fi

log_success "Debug app built ($(get_step_duration "debug-build"))"

print_step 2 3 "Relaunching App"
start_step_timer "launch"

pkill -x "${PROJECT_NAME}" 2>/dev/null || true
sleep 0.5
open -n "${DEBUG_APP_PATH}"

log_success "App launched ($(get_step_duration "launch"))"

print_step 3 3 "Post-launch Checks"

if [ "$VERIFY_PROCESS" = true ]; then
    sleep 1
    if pgrep -x "${PROJECT_NAME}" >/dev/null; then
        log_success "${PROJECT_NAME} process is running"
    else
        log_failure "${PROJECT_NAME} process was not found after launch"
        exit 1
    fi
else
    log_item "Process verification skipped; pass --verify to enable"
fi

print_summary "Debug Build Complete" \
    "App" "${DEBUG_APP_PATH}" \
    "Log" "${BUILD_DIR}/debug-build.log" \
    "Duration" "$(get_total_duration)"

if [ "$SHOW_LOGS" = true ]; then
    log_step "Streaming logs. Press Ctrl-C to stop."
    exec /usr/bin/log stream --style compact --predicate "process == \"${PROJECT_NAME}\""
fi
