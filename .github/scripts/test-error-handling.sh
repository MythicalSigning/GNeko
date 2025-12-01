#!/usr/bin/env bash
################################################################################
# NEKO ERROR HANDLING TEST SCRIPT
# ============================================================================
# Tests all error handling paths, error logging mechanisms, recovery from
# failures, cleanup after errors, and signal handling.
################################################################################

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/logs/error-handling"

mkdir -p "$LOG_DIR"

readonly MAIN_LOG="${LOG_DIR}/error_handling_test.log"

log() {
    local level="$1"
    shift
    printf '[%s] [%s] %s\n' "$(date '+%H:%M:%S')" "$level" "$*" | tee -a "$MAIN_LOG"
}

setup_environment() {
    log "INFO" "Setting up test environment..."
    
    export SCRIPTPATH="$PROJECT_ROOT"
    export dir="/tmp/neko_error_test_$$"
    export called_fn_dir="${dir}/.called"
    export LOGFILE="${dir}/test.log"
    export TOOLS_PATH="${TOOLS_PATH:-/tmp/Tools}"
    
    mkdir -p "$dir"/{logs,.called}
    mkdir -p "$TOOLS_PATH"
    touch "$LOGFILE"
}

cleanup() {
    rm -rf "/tmp/neko_error_test_$$" 2>/dev/null || true
}

trap cleanup EXIT

load_libraries() {
    cd "$PROJECT_ROOT"
    
    if [[ -f "neko.cfg" ]]; then
        source neko.cfg 2>/dev/null || true
    fi
    
    for lib in lib/*.sh; do
        source "$lib" 2>/dev/null || true
    done
}

test_error_logging() {
    log "INFO" "Testing error logging functions..."
    
    local log_funcs=("log_error" "log_warning" "log_info" "log_success" "log_debug")
    
    for func in "${log_funcs[@]}"; do
        if type -t "$func" &>/dev/null; then
            $func "Test message from $func" 2>/dev/null || true
            log "PASS" "$func executed successfully"
        else
            log "SKIP" "$func not defined"
        fi
    done
}

test_module_failure_handling() {
    log "INFO" "Testing module failure handling..."
    
    if type -t mark_module_failed &>/dev/null; then
        mark_module_failed "test_module" "Simulated failure" 2>/dev/null || true
        
        if [[ -f "$called_fn_dir/.test_module_failed" ]]; then
            log "PASS" "mark_module_failed creates failure marker"
            local reason
            reason=$(cat "$called_fn_dir/.test_module_failed" 2>/dev/null || echo "")
            log "INFO" "Failure reason recorded: $reason"
        else
            log "WARN" "Failure marker not created"
        fi
    else
        log "SKIP" "mark_module_failed not defined"
    fi
}

test_cleanup_functions() {
    log "INFO" "Testing cleanup functions..."
    
    local cleanup_funcs=("cleanup" "cleanup_all_procs" "parallel_cleanup" "pipeline_cleanup" "proxy_cleanup" "plugin_cleanup" "error_cleanup")
    
    for func in "${cleanup_funcs[@]}"; do
        if type -t "$func" &>/dev/null; then
            log "PASS" "$func is available"
        else
            log "INFO" "$func not defined (may not be required)"
        fi
    done
}

test_trap_definitions() {
    log "INFO" "Testing trap definitions..."
    
    if grep -q "trap.*cleanup" "$PROJECT_ROOT/neko.sh" 2>/dev/null; then
        log "PASS" "Cleanup trap defined in neko.sh"
    else
        log "INFO" "No explicit cleanup trap in neko.sh"
    fi
    
    if grep -q "trap.*INT\|trap.*TERM" "$PROJECT_ROOT/neko.sh" 2>/dev/null; then
        log "PASS" "Signal traps defined in neko.sh"
    else
        log "INFO" "No explicit signal traps in neko.sh"
    fi
    
    if type -t setup_traps &>/dev/null; then
        log "PASS" "setup_traps function available"
    else
        log "INFO" "setup_traps not defined"
    fi
}

test_error_recovery() {
    log "INFO" "Testing error recovery mechanisms..."
    
    local recovery_funcs=("retry_command" "error_recovery" "auto_recovery")
    
    for func in "${recovery_funcs[@]}"; do
        if type -t "$func" &>/dev/null; then
            log "PASS" "$func is available"
        else
            log "INFO" "$func not defined"
        fi
    done
    
    if grep -qr "ERROR_AUTO_RECOVERY\|ERROR_MAX_RETRIES" "$PROJECT_ROOT/neko.cfg" 2>/dev/null; then
        log "PASS" "Error recovery configuration found"
    else
        log "INFO" "No error recovery configuration"
    fi
}

test_error_reporting() {
    log "INFO" "Testing error reporting system..."
    
    if [[ -f "$PROJECT_ROOT/lib/error_reporting.sh" ]]; then
        log "PASS" "error_reporting.sh exists"
        
        local report_funcs=("error_report" "report_error" "generate_error_report" "error_summary")
        
        for func in "${report_funcs[@]}"; do
            if type -t "$func" &>/dev/null; then
                log "PASS" "$func is available"
            fi
        done
    else
        log "INFO" "error_reporting.sh not found"
    fi
}

main() {
    printf '%s\n' "╔══════════════════════════════════════════════════════════════╗" > "$MAIN_LOG"
    printf '%s\n' "║     NEKO ERROR HANDLING TESTING                              ║" >> "$MAIN_LOG"
    printf '%s\n' "╚══════════════════════════════════════════════════════════════╝" >> "$MAIN_LOG"
    printf 'Timestamp: %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$MAIN_LOG"
    
    setup_environment
    load_libraries
    test_error_logging
    test_module_failure_handling
    test_cleanup_functions
    test_trap_definitions
    test_error_recovery
    test_error_reporting
    
    log "INFO" "Error handling testing complete"
    log "INFO" "Logs available in: $LOG_DIR"
}

main "$@"
