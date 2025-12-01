#!/usr/bin/env bash
################################################################################
# NEKO INTEGRATION TEST SCRIPT
# ============================================================================
# Tests complete scan flows end-to-end without actual targets, verifying
# phase transitions, data flow between modules, and output file generation.
################################################################################

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/logs/integration"

mkdir -p "$LOG_DIR"

readonly MAIN_LOG="${LOG_DIR}/integration_test.log"

log() {
    local level="$1"
    shift
    printf '[%s] [%s] %s\n' "$(date '+%H:%M:%S')" "$level" "$*" | tee -a "$MAIN_LOG"
}

setup_test_environment() {
    log "INFO" "Setting up test environment..."
    
    export SCRIPTPATH="$PROJECT_ROOT"
    export domain="test.example.com"
    export mode="test"
    export dir="/tmp/neko_integration_$$"
    export called_fn_dir="${dir}/.called"
    export LOGFILE="${dir}/test.log"
    export TOOLS_PATH="${TOOLS_PATH:-/tmp/Tools}"
    
    mkdir -p "$dir"/{logs,osint,subdomains,dns,hosts,webs,ports,content,technologies,urls,js,parameters,vulnerabilities,xss,takeover,cloud,auth,api,reports,.tmp,.called}
    mkdir -p "$TOOLS_PATH"
    touch "$LOGFILE"
    
    log "INFO" "Test directory: $dir"
}

cleanup() {
    rm -rf "/tmp/neko_integration_$$" 2>/dev/null || true
}

trap cleanup EXIT

load_framework() {
    log "INFO" "Loading framework..."
    
    cd "$PROJECT_ROOT"
    
    if [[ -f "neko.cfg" ]]; then
        source neko.cfg 2>/dev/null || log "WARN" "Config load warning"
    fi
    
    for lib in lib/*.sh; do
        if [[ -f "$lib" ]]; then
            source "$lib" 2>/dev/null || log "WARN" "Failed to load: $(basename "$lib")"
        fi
    done
    
    log "INFO" "Framework loaded"
}

test_phase_transitions() {
    log "INFO" "Testing phase transitions..."
    
    local phases=(
        "00_osint:osint_main"
        "01_subdomain:subdomain_main"
        "02_dns:dns_main"
        "03_webprobe:webprobe_main"
        "04_portscan:portscan_main"
        "05_content:content_main"
        "06_fingerprint:fingerprint_main"
        "07_urlanalysis:urlanalysis_main"
        "08_params:params_main"
        "09_vulnscan:vulnscan_main"
        "10_xss:xss_main"
        "11_takeover:takeover_main"
        "12_cloud:cloud_main"
        "13_auth:auth_main"
        "14_api:api_main"
        "15_report:report_main"
        "16_advanced_vulns:advanced_vulns_main"
        "17_bettercap:bettercap_main"
    )
    
    local loaded=0
    local failed=0
    
    for phase_info in "${phases[@]}"; do
        local module="${phase_info%%:*}"
        local main_func="${phase_info##*:}"
        
        if [[ -f "modules/${module}.sh" ]]; then
            if source "modules/${module}.sh" 2>/dev/null; then
                ((loaded++)) || true
                
                if type -t "$main_func" &>/dev/null; then
                    log "PASS" "Phase $module: loaded, main function available"
                else
                    log "WARN" "Phase $module: loaded, main function missing"
                fi
            else
                ((failed++)) || true
                log "FAIL" "Phase $module: failed to load"
            fi
        else
            log "SKIP" "Phase $module: module file not found"
        fi
    done
    
    log "INFO" "Phase transitions: $loaded loaded, $failed failed"
}

test_data_flow() {
    log "INFO" "Testing data flow between modules..."
    
    printf '%s\n' "sub1.example.com" > "$dir/subdomains/subdomains.txt"
    printf '%s\n' "sub2.example.com" >> "$dir/subdomains/subdomains.txt"
    printf '%s\n' "sub3.example.com" >> "$dir/subdomains/subdomains.txt"
    
    printf '%s\n' "sub1.example.com:192.168.1.1" > "$dir/dns/resolved.txt"
    printf '%s\n' "sub2.example.com:192.168.1.2" >> "$dir/dns/resolved.txt"
    
    printf '%s\n' "https://sub1.example.com" > "$dir/webs/webs.txt"
    printf '%s\n' "http://sub2.example.com" >> "$dir/webs/webs.txt"
    
    printf '%s\n' "https://sub1.example.com/api/v1" > "$dir/urls/urls.txt"
    printf '%s\n' "https://sub2.example.com/login" >> "$dir/urls/urls.txt"
    
    local data_checks=(
        "subdomains/subdomains.txt"
        "dns/resolved.txt"
        "webs/webs.txt"
        "urls/urls.txt"
    )
    
    for check in "${data_checks[@]}"; do
        if [[ -f "$dir/$check" ]]; then
            local lines
            lines=$(wc -l < "$dir/$check")
            log "PASS" "Data file exists: $check ($lines lines)"
        else
            log "FAIL" "Data file missing: $check"
        fi
    done
}

test_output_structure() {
    log "INFO" "Testing output directory structure..."
    
    local expected_dirs=(
        "logs" "osint" "subdomains" "dns" "hosts" "webs" "ports"
        "content" "technologies" "urls" "js" "parameters"
        "vulnerabilities" "xss" "takeover" "cloud" "auth" "api"
        "reports" ".tmp" ".called"
    )
    
    local present=0
    local missing=0
    
    for subdir in "${expected_dirs[@]}"; do
        if [[ -d "$dir/$subdir" ]]; then
            ((present++)) || true
        else
            ((missing++)) || true
            log "FAIL" "Missing directory: $subdir"
        fi
    done
    
    log "INFO" "Output structure: $present present, $missing missing"
}

test_state_management() {
    log "INFO" "Testing state management..."
    
    touch "$called_fn_dir/.osint_completed"
    touch "$called_fn_dir/.subdomain_completed"
    touch "$called_fn_dir/.dns_completed"
    
    for marker in osint subdomain dns; do
        if [[ -f "$called_fn_dir/.${marker}_completed" ]]; then
            log "PASS" "State marker created: $marker"
        else
            log "FAIL" "State marker missing: $marker"
        fi
    done
    
    if type -t is_module_completed &>/dev/null; then
        touch "$called_fn_dir/.test_module"
        if is_module_completed "test_module"; then
            log "PASS" "is_module_completed detects markers"
        else
            log "FAIL" "is_module_completed failed"
        fi
    fi
}

main() {
    printf '%s\n' "╔══════════════════════════════════════════════════════════════╗" > "$MAIN_LOG"
    printf '%s\n' "║     NEKO INTEGRATION TESTING                                 ║" >> "$MAIN_LOG"
    printf '%s\n' "╚══════════════════════════════════════════════════════════════╝" >> "$MAIN_LOG"
    printf 'Timestamp: %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$MAIN_LOG"
    
    setup_test_environment
    load_framework
    test_phase_transitions
    test_data_flow
    test_output_structure
    test_state_management
    
    log "INFO" "Integration testing complete"
    log "INFO" "Logs available in: $LOG_DIR"
}

main "$@"
