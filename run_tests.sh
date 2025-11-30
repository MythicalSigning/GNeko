#!/usr/bin/env bash

#  ███╗   ██╗███████╗██╗  ██╗ ██████╗     ████████╗███████╗███████╗████████╗███████╗
#  ████╗  ██║██╔════╝██║ ██╔╝██╔═══██╗    ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔════╝
#  ██╔██╗ ██║█████╗  █████╔╝ ██║   ██║       ██║   █████╗  ███████╗   ██║   ███████╗
#  ██║╚██╗██║██╔══╝  ██╔═██╗ ██║   ██║       ██║   ██╔══╝  ╚════██║   ██║   ╚════██║
#  ██║ ╚████║███████╗██║  ██╗╚██████╔╝       ██║   ███████╗███████║   ██║   ███████║
#  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝        ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚══════╝
#
# Neko Test Suite - Comprehensive Error Detection
# This script runs all tests locally to help identify errors before CI/CD
# Version: 1.0.0

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m'
BOLD='\033[1m'

# Script path
SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPTPATH}/test_logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
TESTS_TOTAL=0

# ═══════════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

log_header() {
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${WHITE}  $1${RESET}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════════════════════${RESET}"
    echo ""
}

log_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}  $1${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

log_test() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "  ${BLUE}[TEST]${RESET} $1"
}

log_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "    ${GREEN}✅ PASS${RESET}: $1"
}

log_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "    ${RED}❌ FAIL${RESET}: $1"
}

log_skip() {
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    echo -e "    ${YELLOW}⏭️ SKIP${RESET}: $1"
}

log_info() {
    echo -e "    ${WHITE}ℹ️ INFO${RESET}: $1"
}

log_warning() {
    echo -e "    ${YELLOW}⚠️ WARN${RESET}: $1"
}

log_error() {
    echo -e "    ${RED}🔴 ERROR${RESET}: $1"
}

# ═══════════════════════════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════════════════════════

show_banner() {
    echo -e "${MAGENTA}"
    echo "  ███╗   ██╗███████╗██╗  ██╗ ██████╗     ████████╗███████╗███████╗████████╗███████╗"
    echo "  ████╗  ██║██╔════╝██║ ██╔╝██╔═══██╗    ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔════╝"
    echo "  ██╔██╗ ██║█████╗  █████╔╝ ██║   ██║       ██║   █████╗  ███████╗   ██║   ███████╗"
    echo "  ██║╚██╗██║██╔══╝  ██╔═██╗ ██║   ██║       ██║   ██╔══╝  ╚════██║   ██║   ╚════██║"
    echo "  ██║ ╚████║███████╗██║  ██╗╚██████╔╝       ██║   ███████╗███████║   ██║   ███████║"
    echo "  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝        ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚══════╝"
    echo -e "${RESET}"
    echo -e "  ${CYAN}Comprehensive Error Detection Suite${RESET}"
    echo -e "  ${WHITE}Version: 1.0.0${RESET}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# SETUP
# ═══════════════════════════════════════════════════════════════════════════════

setup_test_environment() {
    log_section "Setting Up Test Environment"
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    echo "Log directory: $LOG_DIR"
    
    # Create test output directory
    export TEST_OUTPUT_DIR="${SCRIPTPATH}/.test_output"
    mkdir -p "$TEST_OUTPUT_DIR"
    echo "Test output: $TEST_OUTPUT_DIR"
    
    # Set up environment variables
    export SCRIPTPATH
    export LIB_PATH="${SCRIPTPATH}/lib"
    export MODULES_PATH="${SCRIPTPATH}/modules"
    export CONFIG_PATH="${SCRIPTPATH}/config"
    export LOGFILE="${LOG_DIR}/test_${TIMESTAMP}.log"
    export called_fn_dir="${TEST_OUTPUT_DIR}/.called"
    export dir="${TEST_OUTPUT_DIR}/output"
    export DEBUG=true
    export domain="test.example.com"
    export mode="test"
    
    # Create required subdirectories
    mkdir -p "$called_fn_dir"
    mkdir -p "$dir"/{logs,osint,subdomains,dns,hosts,webs,ports,content,technologies,urls,js,parameters,vulnerabilities,xss,takeover,cloud,auth,api,reports,.tmp}
    
    touch "$LOGFILE"
    
    log_pass "Test environment configured"
}

cleanup_test_environment() {
    log_section "Cleaning Up Test Environment"
    
    if [[ -d "$TEST_OUTPUT_DIR" ]]; then
        rm -rf "$TEST_OUTPUT_DIR"
        log_info "Removed test output directory"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: SYNTAX VALIDATION
# ═══════════════════════════════════════════════════════════════════════════════

test_syntax_validation() {
    log_header "TEST SUITE: Syntax Validation"
    
    local syntax_errors=0
    local files_checked=0
    
    # Find all shell scripts
    while IFS= read -r -d '' script; do
        files_checked=$((files_checked + 1))
        log_test "Syntax check: $(basename "$script")"
        
        if bash -n "$script" 2>"${LOG_DIR}/syntax_$(basename "$script").log"; then
            log_pass "Valid syntax"
        else
            log_fail "Syntax errors found"
            log_error "$(cat "${LOG_DIR}/syntax_$(basename "$script").log")"
            syntax_errors=$((syntax_errors + 1))
        fi
    done < <(find "$SCRIPTPATH" -name "*.sh" -type f -print0 2>/dev/null)
    
    log_section "Syntax Validation Summary"
    echo "  Files checked: $files_checked"
    echo "  Errors found: $syntax_errors"
    
    if [[ $syntax_errors -eq 0 ]]; then
        log_pass "All syntax checks passed"
        return 0
    else
        log_fail "$syntax_errors files have syntax errors"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: CONFIGURATION VALIDATION
# ═══════════════════════════════════════════════════════════════════════════════

test_configuration() {
    log_header "TEST SUITE: Configuration Validation"
    
    local config_file="${SCRIPTPATH}/neko.cfg"
    
    log_test "Configuration file exists"
    if [[ -f "$config_file" ]]; then
        log_pass "neko.cfg found"
    else
        log_fail "neko.cfg not found"
        return 1
    fi
    
    log_test "Configuration syntax"
    if bash -n "$config_file" 2>"${LOG_DIR}/config_syntax.log"; then
        log_pass "Configuration syntax valid"
    else
        log_fail "Configuration syntax errors"
        log_error "$(cat "${LOG_DIR}/config_syntax.log")"
        return 1
    fi
    
    log_test "Loading configuration"
    if source "$config_file" 2>"${LOG_DIR}/config_load.log"; then
        log_pass "Configuration loaded successfully"
    else
        log_fail "Configuration failed to load"
        log_error "$(cat "${LOG_DIR}/config_load.log")"
        return 1
    fi
    
    log_test "Required variables defined"
    local required_vars=(
        "TOOLS_PATH"
        "USER_AGENT"
        "OSINT_ENABLED"
        "SUBDOMAIN_ENABLED"
        "PARALLEL_ENABLED"
        "LOGGING_ENABLED"
    )
    
    local missing_vars=0
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var+x}" ]]; then
            log_warning "Missing variable: $var"
            missing_vars=$((missing_vars + 1))
        fi
    done
    
    if [[ $missing_vars -eq 0 ]]; then
        log_pass "All required variables defined"
    else
        log_fail "$missing_vars required variables missing"
    fi
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: LIBRARY LOADING
# ═══════════════════════════════════════════════════════════════════════════════

test_library_loading() {
    log_header "TEST SUITE: Library Loading"
    
    local lib_dir="${SCRIPTPATH}/lib"
    
    log_test "Library directory exists"
    if [[ -d "$lib_dir" ]]; then
        log_pass "lib/ directory found"
    else
        log_fail "lib/ directory not found"
        return 1
    fi
    
    # Load configuration first
    source "${SCRIPTPATH}/neko.cfg" 2>/dev/null || true
    
    # Libraries to test in order
    local libraries=(
        "core.sh"
        "logging.sh"
        "discord_notifications.sh"
        "parallel.sh"
        "async_pipeline.sh"
        "error_handling.sh"
        "error_reporting.sh"
        "queue_manager.sh"
        "data_flow_bus.sh"
        "orchestrator.sh"
        "proxy_rotation.sh"
        "intelligence.sh"
        "plugin.sh"
    )
    
    local load_success=0
    local load_fail=0
    
    for lib in "${libraries[@]}"; do
        log_test "Loading: $lib"
        
        if [[ -f "${lib_dir}/${lib}" ]]; then
            if source "${lib_dir}/${lib}" 2>"${LOG_DIR}/lib_${lib%.sh}.log"; then
                log_pass "Loaded successfully"
                load_success=$((load_success + 1))
            else
                log_fail "Failed to load"
                log_error "$(head -5 "${LOG_DIR}/lib_${lib%.sh}.log")"
                load_fail=$((load_fail + 1))
            fi
        else
            log_skip "File not found"
        fi
    done
    
    log_section "Library Loading Summary"
    echo "  Successful: $load_success"
    echo "  Failed: $load_fail"
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: CORE FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

test_core_functions() {
    log_header "TEST SUITE: Core Function Testing"
    
    # Ensure core library is loaded
    source "${SCRIPTPATH}/lib/core.sh" 2>/dev/null || true
    
    # Test command_exists
    log_test "command_exists function"
    if type -t command_exists &>/dev/null; then
        if command_exists bash; then
            log_pass "command_exists works correctly"
        else
            log_fail "command_exists returned false for bash"
        fi
    else
        log_skip "command_exists not defined"
    fi
    
    # Test validate_domain
    log_test "validate_domain function"
    if type -t validate_domain &>/dev/null; then
        local domain_tests=(
            "example.com:0"
            "sub.example.com:0"
            "192.168.1.1:0"
            "10.0.0.0/24:0"
            "invalid domain:1"
            "-invalid.com:1"
        )
        
        local domain_pass=0
        local domain_fail=0
        
        for test in "${domain_tests[@]}"; do
            local test_domain="${test%:*}"
            local expected="${test#*:}"
            
            if validate_domain "$test_domain" 2>/dev/null; then
                result=0
            else
                result=1
            fi
            
            if [[ "$result" == "$expected" ]]; then
                domain_pass=$((domain_pass + 1))
            else
                domain_fail=$((domain_fail + 1))
                log_warning "validate_domain '$test_domain': got $result, expected $expected"
            fi
        done
        
        if [[ $domain_fail -eq 0 ]]; then
            log_pass "All domain validation tests passed ($domain_pass tests)"
        else
            log_fail "$domain_fail domain validation tests failed"
        fi
    else
        log_skip "validate_domain not defined"
    fi
    
    # Test is_ip
    log_test "is_ip function"
    if type -t is_ip &>/dev/null; then
        if is_ip "192.168.1.1" && ! is_ip "example.com"; then
            log_pass "is_ip works correctly"
        else
            log_fail "is_ip returned unexpected results"
        fi
    else
        log_skip "is_ip not defined"
    fi
    
    # Test ensure_dir
    log_test "ensure_dir function"
    if type -t ensure_dir &>/dev/null; then
        local test_dir="/tmp/neko_test_$$"
        ensure_dir "$test_dir"
        if [[ -d "$test_dir" ]]; then
            log_pass "ensure_dir creates directories"
            rmdir "$test_dir"
        else
            log_fail "ensure_dir failed to create directory"
        fi
    else
        log_skip "ensure_dir not defined"
    fi
    
    # Test timestamp
    log_test "timestamp function"
    if type -t timestamp &>/dev/null; then
        local ts=$(timestamp)
        if [[ "$ts" =~ ^[0-9]{8}_[0-9]{6}$ ]]; then
            log_pass "timestamp format correct: $ts"
        else
            log_fail "timestamp format incorrect: $ts"
        fi
    else
        log_skip "timestamp not defined"
    fi
    
    # Test count_lines
    log_test "count_lines function"
    if type -t count_lines &>/dev/null; then
        echo -e "line1\nline2\nline3" > /tmp/test_count_$$
        local count=$(count_lines /tmp/test_count_$$)
        rm -f /tmp/test_count_$$
        
        if [[ "$count" == "3" ]]; then
            log_pass "count_lines returns correct count: $count"
        else
            log_fail "count_lines returned: $count (expected: 3)"
        fi
    else
        log_skip "count_lines not defined"
    fi
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: MODULE LOADING
# ═══════════════════════════════════════════════════════════════════════════════

test_module_loading() {
    log_header "TEST SUITE: Module Loading"
    
    local modules_dir="${SCRIPTPATH}/modules"
    
    log_test "Modules directory exists"
    if [[ -d "$modules_dir" ]]; then
        log_pass "modules/ directory found"
    else
        log_fail "modules/ directory not found"
        return 1
    fi
    
    # Load all libraries first
    source "${SCRIPTPATH}/neko.cfg" 2>/dev/null || true
    for lib in "${SCRIPTPATH}"/lib/*.sh; do
        source "$lib" 2>/dev/null || true
    done
    
    # Expected modules
    local modules=(
        "00_osint.sh"
        "01_subdomain.sh"
        "02_dns.sh"
        "03_webprobe.sh"
        "04_portscan.sh"
        "05_content.sh"
        "06_fingerprint.sh"
        "07_urlanalysis.sh"
        "08_params.sh"
        "09_vulnscan.sh"
        "10_xss.sh"
        "11_takeover.sh"
        "12_cloud.sh"
        "13_auth.sh"
        "14_api.sh"
        "15_report.sh"
        "16_advanced_vulns.sh"
        "17_bettercap.sh"
    )
    
    local load_success=0
    local load_fail=0
    
    for module in "${modules[@]}"; do
        log_test "Loading: $module"
        
        if [[ -f "${modules_dir}/${module}" ]]; then
            if source "${modules_dir}/${module}" 2>"${LOG_DIR}/module_${module%.sh}.log"; then
                log_pass "Loaded successfully"
                load_success=$((load_success + 1))
                
                # Check for main function
                local main_func=$(echo "$module" | sed 's/^[0-9]*_//' | sed 's/\.sh$//')_main
                if type -t "$main_func" &>/dev/null; then
                    log_info "Main function available: $main_func"
                else
                    log_warning "Main function not found: $main_func"
                fi
            else
                log_fail "Failed to load"
                load_fail=$((load_fail + 1))
            fi
        else
            log_skip "File not found: $module"
        fi
    done
    
    log_section "Module Loading Summary"
    echo "  Successful: $load_success"
    echo "  Failed: $load_fail"
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: MAIN SCRIPT
# ═══════════════════════════════════════════════════════════════════════════════

test_main_script() {
    log_header "TEST SUITE: Main Script Testing"
    
    local main_script="${SCRIPTPATH}/neko.sh"
    
    log_test "Main script exists"
    if [[ -f "$main_script" ]]; then
        log_pass "neko.sh found"
    else
        log_fail "neko.sh not found"
        return 1
    fi
    
    log_test "Main script is executable"
    chmod +x "$main_script"
    if [[ -x "$main_script" ]]; then
        log_pass "neko.sh is executable"
    else
        log_fail "neko.sh is not executable"
    fi
    
    log_test "Help command"
    if "$main_script" --help >"${LOG_DIR}/help_output.log" 2>&1; then
        log_pass "Help command executed"
        log_info "$(head -5 "${LOG_DIR}/help_output.log")"
    else
        log_fail "Help command failed"
    fi
    
    log_test "Version command"
    local version=$("$main_script" --version 2>&1)
    if [[ "$version" =~ ^Neko ]]; then
        log_pass "Version: $version"
    else
        log_warning "Version output: $version"
    fi
    
    log_test "Check-tools command"
    if "$main_script" --check-tools >"${LOG_DIR}/check_tools.log" 2>&1; then
        log_pass "Check-tools executed"
    else
        log_warning "Check-tools returned non-zero (missing tools expected)"
    fi
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# TEST: FILE STRUCTURE
# ═══════════════════════════════════════════════════════════════════════════════

test_file_structure() {
    log_header "TEST SUITE: File Structure Validation"
    
    # Required directories
    local required_dirs=(
        "modules"
        "lib"
        "config"
        "plugins"
    )
    
    for dir in "${required_dirs[@]}"; do
        log_test "Directory: $dir/"
        if [[ -d "${SCRIPTPATH}/${dir}" ]]; then
            local file_count=$(find "${SCRIPTPATH}/${dir}" -type f | wc -l)
            log_pass "Found ($file_count files)"
        else
            log_fail "Not found"
        fi
    done
    
    # Required files
    local required_files=(
        "neko.sh"
        "neko.cfg"
        "install.sh"
        "README.md"
    )
    
    for file in "${required_files[@]}"; do
        log_test "File: $file"
        if [[ -f "${SCRIPTPATH}/${file}" ]]; then
            local lines=$(wc -l < "${SCRIPTPATH}/${file}")
            log_pass "Found ($lines lines)"
        else
            log_fail "Not found"
        fi
    done
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# GENERATE REPORT
# ═══════════════════════════════════════════════════════════════════════════════

generate_report() {
    log_header "TEST REPORT"
    
    local report_file="${LOG_DIR}/test_report_${TIMESTAMP}.txt"
    
    {
        echo "═══════════════════════════════════════════════════════════════"
        echo "NEKO TEST REPORT"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "Date: $(date)"
        echo "Test Run ID: $TIMESTAMP"
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "SUMMARY"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "Total Tests: $TESTS_TOTAL"
        echo "Passed: $TESTS_PASSED"
        echo "Failed: $TESTS_FAILED"
        echo "Skipped: $TESTS_SKIPPED"
        echo ""
        
        if [[ $TESTS_FAILED -eq 0 ]]; then
            echo "RESULT: ✅ ALL TESTS PASSED"
        else
            echo "RESULT: ❌ SOME TESTS FAILED"
        fi
        
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "LOG FILES"
        echo "═══════════════════════════════════════════════════════════════"
        find "$LOG_DIR" -name "*.log" -type f | while read -r log; do
            echo "  - $(basename "$log")"
        done
    } | tee "$report_file"
    
    echo ""
    echo -e "${CYAN}Full report saved to: ${report_file}${RESET}"
    echo -e "${CYAN}Log directory: ${LOG_DIR}${RESET}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    show_banner
    
    # Parse arguments
    local run_all=true
    local run_syntax=false
    local run_config=false
    local run_library=false
    local run_module=false
    local run_main=false
    local run_structure=false
    local run_cleanup=true
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --syntax)
                run_all=false
                run_syntax=true
                shift
                ;;
            --config)
                run_all=false
                run_config=true
                shift
                ;;
            --library)
                run_all=false
                run_library=true
                shift
                ;;
            --module)
                run_all=false
                run_module=true
                shift
                ;;
            --main)
                run_all=false
                run_main=true
                shift
                ;;
            --structure)
                run_all=false
                run_structure=true
                shift
                ;;
            --no-cleanup)
                run_cleanup=false
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --syntax      Run only syntax validation"
                echo "  --config      Run only configuration tests"
                echo "  --library     Run only library loading tests"
                echo "  --module      Run only module loading tests"
                echo "  --main        Run only main script tests"
                echo "  --structure   Run only file structure tests"
                echo "  --no-cleanup  Don't cleanup test files"
                echo "  --help, -h    Show this help"
                echo ""
                echo "Without options, all tests will be run."
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Setup
    setup_test_environment
    
    # Run tests
    if [[ "$run_all" == "true" ]] || [[ "$run_structure" == "true" ]]; then
        test_file_structure
    fi
    
    if [[ "$run_all" == "true" ]] || [[ "$run_syntax" == "true" ]]; then
        test_syntax_validation
    fi
    
    if [[ "$run_all" == "true" ]] || [[ "$run_config" == "true" ]]; then
        test_configuration
    fi
    
    if [[ "$run_all" == "true" ]] || [[ "$run_library" == "true" ]]; then
        test_library_loading
        test_core_functions
    fi
    
    if [[ "$run_all" == "true" ]] || [[ "$run_module" == "true" ]]; then
        test_module_loading
    fi
    
    if [[ "$run_all" == "true" ]] || [[ "$run_main" == "true" ]]; then
        test_main_script
    fi
    
    # Generate report
    generate_report
    
    # Cleanup
    if [[ "$run_cleanup" == "true" ]]; then
        cleanup_test_environment
    fi
    
    # Exit with appropriate code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}${BOLD}All tests passed! ✅${RESET}"
        exit 0
    else
        echo ""
        echo -e "${RED}${BOLD}$TESTS_FAILED tests failed! ❌${RESET}"
        exit 1
    fi
}

main "$@"
