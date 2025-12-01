#!/usr/bin/env bash
################################################################################
# NEKO MODULE LOADING TEST SCRIPT
# ============================================================================
# This script tests module loading in isolation with proper error handling.
# It is designed to be run from GitHub Actions workflows.
################################################################################

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/logs/module"

# Create log directory
mkdir -p "$LOG_DIR"

# Log files
readonly MOD_LOG="${LOG_DIR}/module_loading.log"
readonly MOD_ERRORS="${LOG_DIR}/module_errors.log"
readonly FUNC_MAP="${LOG_DIR}/function_map.log"

# Safe logging function
log() {
    local level="$1"
    shift
    local message="$*"
    printf '[%s] %s\n' "$level" "$message" | tee -a "$MOD_LOG"
}

log_to_file() {
    printf '%s\n' "$*" >> "$MOD_LOG"
}

# Initialize logs
init_logs() {
    printf '%s\n' "========================================"  > "$MOD_LOG"
    printf '%s\n' "NEKO MODULE LOADING TEST"               >> "$MOD_LOG"
    printf '%s\n' "========================================"  >> "$MOD_LOG"
    printf '%s\n' "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')" >> "$MOD_LOG"
    printf '%s\n' "Project Root: $PROJECT_ROOT"             >> "$MOD_LOG"
    printf '%s\n' ""                                         >> "$MOD_LOG"
    
    : > "$MOD_ERRORS"
    printf '%s\n' "Module|Expected Function|Load Status|Function Status" > "$FUNC_MAP"
    printf '%s\n' "------|-----------------|-----------|----------------" >> "$FUNC_MAP"
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
    export dir="/tmp/neko_module_test_$$"
    export called_fn_dir="${dir}/.called"
    export LOGFILE="${dir}/test.log"
    export TOOLS_PATH="${TOOLS_PATH:-/tmp/Tools}"
    
    # Create all expected directories
    mkdir -p "$dir"/{logs,.tmp,.called,osint,subdomains,dns,hosts,webs,ports,content,technologies,urls,js,parameters,vulnerabilities,xss,takeover,cloud,auth,api,reports}
    mkdir -p "$TOOLS_PATH"
    touch "$LOGFILE"
    
    log "INFO" "Test directory: $dir"
}

# Cleanup function
cleanup() {
    local exit_code=$?
    rm -rf "/tmp/neko_module_test_$$" 2>/dev/null || true
    return $exit_code
}

trap cleanup EXIT

# Load prerequisites
load_prerequisites() {
    log "INFO" "Loading prerequisites..."
    log_to_file ""
    log_to_file "=== Loading Prerequisites ==="
    
    cd "$PROJECT_ROOT"
    
    # Load configuration
    if [[ -f "neko.cfg" ]]; then
        source neko.cfg 2>/dev/null || true
        log "INFO" "Configuration loaded"
    fi
    
    # Load all libraries
    local lib_count=0
    for lib in lib/*.sh; do
        if [[ -f "$lib" ]]; then
            source "$lib" 2>/dev/null || true
            ((lib_count++))
        fi
    done
    
    log "INFO" "Loaded $lib_count libraries"
}

# Test module loading
test_module_loading() {
    # Module definitions with expected main functions
    declare -A module_functions=(
        ["00_osint.sh"]="osint_main"
        ["01_subdomain.sh"]="subdomain_main"
        ["02_dns.sh"]="dns_main"
        ["03_webprobe.sh"]="webprobe_main"
        ["04_portscan.sh"]="portscan_main"
        ["05_content.sh"]="content_main"
        ["06_fingerprint.sh"]="fingerprint_main"
        ["07_urlanalysis.sh"]="urlanalysis_main"
        ["08_params.sh"]="param_main"
        ["09_vulnscan.sh"]="vulnscan_main"
        ["10_xss.sh"]="xss_main"
        ["11_takeover.sh"]="takeover_main"
        ["12_cloud.sh"]="cloud_main"
        ["13_auth.sh"]="auth_main"
        ["14_api.sh"]="api_main"
        ["15_report.sh"]="report_main"
        ["16_advanced_vulns.sh"]="advanced_vulns_main"
        ["17_bettercap.sh"]="bettercap_main"
    )
    
    local load_success=0
    local load_fail=0
    local func_found=0
    local func_missing=0
    
    log "INFO" "Testing module loading..."
    log_to_file ""
    log_to_file "=== Loading Modules ==="
    
    cd "$PROJECT_ROOT"
    
    for module in modules/*.sh; do
        if [[ ! -f "$module" ]]; then
            continue
        fi
        
        local module_name
        module_name=$(basename "$module")
        local expected_func="${module_functions[$module_name]:-unknown}"
        local load_status="UNKNOWN"
        local func_status="N/A"
        
        log_to_file ""
        log_to_file "--- Loading: $module_name ---"
        
        # Get file info
        local lines
        lines=$(wc -l < "$module" 2>/dev/null || echo "0")
        log_to_file "Lines: $lines"
        
        # Try to source the module
        local load_output
        if load_output=$(source "$module" 2>&1); then
            log "PASS" "$module_name loaded"
            log_to_file "Status: LOADED"
            load_status="LOADED"
            ((load_success++))
            
            # Check for expected main function
            if [[ "$expected_func" != "unknown" ]]; then
                if type -t "$expected_func" &>/dev/null; then
                    log "INFO" "  Function $expected_func: FOUND"
                    log_to_file "Function $expected_func: FOUND"
                    func_status="FOUND"
                    ((func_found++))
                else
                    log "WARN" "  Function $expected_func: MISSING"
                    log_to_file "Function $expected_func: MISSING"
                    func_status="MISSING"
                    ((func_missing++))
                fi
            fi
        else
            log "FAIL" "$module_name failed to load"
            log_to_file "Status: FAILED"
            log_to_file "Error: $load_output"
            load_status="FAILED"
            printf '%s: %s\n' "$module_name" "$load_output" >> "$MOD_ERRORS"
            ((load_fail++))
        fi
        
        # Update function map
        printf '%s|%s|%s|%s\n' "$module_name" "$expected_func" "$load_status" "$func_status" >> "$FUNC_MAP"
    done
    
    log_to_file ""
    log_to_file "========================================"
    log "INFO" "Module Loading Summary:"
    log "INFO" "  Modules Loaded: $load_success"
    log "INFO" "  Modules Failed: $load_fail"
    log "INFO" "  Functions Found: $func_found"
    log "INFO" "  Functions Missing: $func_missing"
    log_to_file "========================================"
    
    # Return failure if any modules failed
    if [[ $load_fail -gt 0 ]]; then
        log "ERROR" "$load_fail modules failed to load"
        return 1
    fi
    
    return 0
}

# Main
main() {
    init_logs
    setup_environment
    load_prerequisites
    
    local exit_code=0
    
    if ! test_module_loading; then
        exit_code=1
    fi
    
    log "INFO" "Test complete. Logs available in: $LOG_DIR"
    
    # Display function map
    printf '\n%s\n' "=== Function Availability Map ==="
    cat "$FUNC_MAP"
    
    return $exit_code
}

main "$@"
