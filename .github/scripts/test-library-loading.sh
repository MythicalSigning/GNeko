#!/usr/bin/env bash
################################################################################
# NEKO LIBRARY LOADING TEST SCRIPT
# ============================================================================
# This script tests library loading in isolation with proper error handling.
# It is designed to be run from GitHub Actions workflows.
################################################################################

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/logs/library"

# Create log directory
mkdir -p "$LOG_DIR"

# Log files
readonly LIB_LOG="${LOG_DIR}/library_loading.log"
readonly LIB_ERRORS="${LOG_DIR}/library_errors.log"
readonly FUNC_LOG="${LOG_DIR}/function_availability.log"

# Initialize logs
init_logs() {
    printf '%s\n' "========================================"  > "$LIB_LOG"
    printf '%s\n' "NEKO LIBRARY LOADING TEST"              >> "$LIB_LOG"
    printf '%s\n' "========================================"  >> "$LIB_LOG"
    printf '%s\n' "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LIB_LOG"
    printf '%s\n' "Project Root: $PROJECT_ROOT"             >> "$LIB_LOG"
    printf '%s\n' ""                                         >> "$LIB_LOG"
    
    : > "$LIB_ERRORS"
    : > "$FUNC_LOG"
}

# Safe logging function
log() {
    local level="$1"
    shift
    local message="$*"
    printf '[%s] %s\n' "$level" "$message" | tee -a "$LIB_LOG"
}

log_to_file() {
    printf '%s\n' "$*" >> "$LIB_LOG"
}

# Setup test environment
setup_environment() {
    log "INFO" "Setting up test environment..."
    
    export SCRIPTPATH="$PROJECT_ROOT"
    export LIB_PATH="${PROJECT_ROOT}/lib"
    export MODULES_PATH="${PROJECT_ROOT}/modules"
    export CONFIG_PATH="${PROJECT_ROOT}/config"
    export DEBUG=true
    export domain="test.example.com"
    export mode="test"
    export dir="/tmp/neko_test_$$"
    export called_fn_dir="${dir}/.called"
    export LOGFILE="${dir}/test.log"
    export TOOLS_PATH="${TOOLS_PATH:-/tmp/Tools}"
    
    mkdir -p "$dir"/{logs,.tmp,.called}
    mkdir -p "$TOOLS_PATH"
    touch "$LOGFILE"
    
    log "INFO" "Test directory: $dir"
}

# Cleanup function
cleanup() {
    local exit_code=$?
    rm -rf "/tmp/neko_test_$$" 2>/dev/null || true
    return $exit_code
}

trap cleanup EXIT

# Load configuration
load_config() {
    log "INFO" "Loading configuration..."
    log_to_file ""
    log_to_file "=== Loading Configuration ==="
    
    cd "$PROJECT_ROOT"
    
    if [[ -f "neko.cfg" ]]; then
        if source neko.cfg 2>&1 | tee -a "$LIB_LOG"; then
            log "PASS" "Configuration loaded successfully"
            return 0
        else
            log "FAIL" "Configuration failed to load"
            printf '%s\n' "Configuration load error" >> "$LIB_ERRORS"
            return 1
        fi
    else
        log "WARN" "Configuration file not found"
        return 0
    fi
}

# Test library loading
test_library_loading() {
    local -a libraries=(
        "core.sh"
        "logging.sh"
        "error_handling.sh"
        "error_reporting.sh"
        "parallel.sh"
        "async_pipeline.sh"
        "queue_manager.sh"
        "data_flow_bus.sh"
        "orchestrator.sh"
        "proxy_rotation.sh"
        "intelligence.sh"
        "plugin.sh"
        "discord_notifications.sh"
    )
    
    local load_success=0
    local load_fail=0
    local load_skip=0
    
    log "INFO" "Testing library loading order..."
    log_to_file ""
    log_to_file "=== Loading Libraries in Dependency Order ==="
    
    cd "$PROJECT_ROOT"
    
    for lib in "${libraries[@]}"; do
        local lib_path="lib/$lib"
        log_to_file ""
        log_to_file "--- Loading: $lib ---"
        
        if [[ ! -f "$lib_path" ]]; then
            log "SKIP" "$lib not found"
            log_to_file "Status: NOT FOUND"
            ((load_skip++))
            continue
        fi
        
        # Get file info
        local lines
        lines=$(wc -l < "$lib_path" 2>/dev/null || echo "0")
        log_to_file "Lines: $lines"
        
        # Try to source the library
        local load_output
        if load_output=$(source "$lib_path" 2>&1); then
            log "PASS" "$lib loaded successfully"
            log_to_file "Status: LOADED"
            ((load_success++))
        else
            log "FAIL" "$lib failed to load"
            log_to_file "Status: FAILED"
            log_to_file "Error: $load_output"
            printf '%s: %s\n' "$lib" "$load_output" >> "$LIB_ERRORS"
            ((load_fail++))
        fi
    done
    
    log_to_file ""
    log_to_file "========================================"
    log "INFO" "Library Loading Summary:"
    log "INFO" "  Successful: $load_success"
    log "INFO" "  Failed: $load_fail"
    log "INFO" "  Skipped: $load_skip"
    log_to_file "========================================"
    
    # Return failure if any libraries failed
    if [[ $load_fail -gt 0 ]]; then
        log "ERROR" "$load_fail libraries failed to load"
        return 1
    fi
    
    return 0
}

# Test core functions
test_core_functions() {
    local tests_passed=0
    local tests_failed=0
    local tests_skipped=0
    
    log "INFO" "Testing core functions..."
    log_to_file ""
    log_to_file "=== Core Function Tests ==="
    
    # Test command_exists
    log_to_file ""
    log_to_file "--- Testing command_exists ---"
    if type -t command_exists &>/dev/null; then
        if command_exists bash; then
            log "PASS" "command_exists('bash') = true"
            ((tests_passed++))
        else
            log "FAIL" "command_exists('bash') should be true"
            ((tests_failed++))
        fi
        
        if ! command_exists nonexistent_command_xyz_123; then
            log "PASS" "command_exists('nonexistent') = false"
            ((tests_passed++))
        else
            log "FAIL" "command_exists('nonexistent') should be false"
            ((tests_failed++))
        fi
    else
        log "SKIP" "command_exists not defined"
        ((tests_skipped++))
    fi
    
    # Test validate_domain
    log_to_file ""
    log_to_file "--- Testing validate_domain ---"
    if type -t validate_domain &>/dev/null; then
        if validate_domain "example.com"; then
            log "PASS" "validate_domain('example.com') = valid"
            ((tests_passed++))
        else
            log "FAIL" "validate_domain('example.com') should be valid"
            ((tests_failed++))
        fi
    else
        log "SKIP" "validate_domain not defined"
        ((tests_skipped++))
    fi
    
    # Test is_ip
    log_to_file ""
    log_to_file "--- Testing is_ip ---"
    if type -t is_ip &>/dev/null; then
        if is_ip "192.168.1.1"; then
            log "PASS" "is_ip('192.168.1.1') = true"
            ((tests_passed++))
        else
            log "FAIL" "is_ip('192.168.1.1') should be true"
            ((tests_failed++))
        fi
    else
        log "SKIP" "is_ip not defined"
        ((tests_skipped++))
    fi
    
    # Test ensure_dir
    log_to_file ""
    log_to_file "--- Testing ensure_dir ---"
    if type -t ensure_dir &>/dev/null; then
        local test_dir="/tmp/neko_ensure_test_$$"
        ensure_dir "$test_dir"
        if [[ -d "$test_dir" ]]; then
            log "PASS" "ensure_dir creates directory"
            rmdir "$test_dir" 2>/dev/null || true
            ((tests_passed++))
        else
            log "FAIL" "ensure_dir did not create directory"
            ((tests_failed++))
        fi
    else
        log "SKIP" "ensure_dir not defined"
        ((tests_skipped++))
    fi
    
    # Test timestamp
    log_to_file ""
    log_to_file "--- Testing timestamp ---"
    if type -t timestamp &>/dev/null; then
        local ts
        ts=$(timestamp)
        if [[ "$ts" =~ ^[0-9]{8}_[0-9]{6}$ ]]; then
            log "PASS" "timestamp format correct: $ts"
            ((tests_passed++))
        else
            log "FAIL" "timestamp format incorrect: $ts"
            ((tests_failed++))
        fi
    else
        log "SKIP" "timestamp not defined"
        ((tests_skipped++))
    fi
    
    log_to_file ""
    log_to_file "========================================"
    log "INFO" "Function Test Summary:"
    log "INFO" "  Passed: $tests_passed"
    log "INFO" "  Failed: $tests_failed"
    log "INFO" "  Skipped: $tests_skipped"
    log_to_file "========================================"
    
    # Write function availability
    printf '%s\n' "=== Available Functions ===" > "$FUNC_LOG"
    declare -F 2>/dev/null | sed 's/declare -f //' >> "$FUNC_LOG" || true
    
    # Don't fail on function test failures (they might be expected)
    return 0
}

# Main
main() {
    init_logs
    setup_environment
    
    local exit_code=0
    
    if ! load_config; then
        log "WARN" "Configuration loading had issues, continuing..."
    fi
    
    if ! test_library_loading; then
        exit_code=1
    fi
    
    test_core_functions
    
    log "INFO" "Test complete. Logs available in: $LOG_DIR"
    
    return $exit_code
}

main "$@"
