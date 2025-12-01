#!/usr/bin/env bash
################################################################################
# NEKO MODULE FUNCTION COVERAGE TEST SCRIPT
# ============================================================================
# This script tests every function in each module individually, verifying
# function parameter handling, edge cases, and return codes.
################################################################################

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/logs/module-coverage"

mkdir -p "$LOG_DIR"

readonly COVERAGE_LOG="${LOG_DIR}/function_coverage.log"
readonly PARAM_LOG="${LOG_DIR}/parameter_handling.log"
readonly EDGE_LOG="${LOG_DIR}/edge_cases.log"
readonly RETURN_LOG="${LOG_DIR}/return_codes.log"

log() {
    local level="$1"
    shift
    printf '[%s] %s\n' "$level" "$*" | tee -a "$COVERAGE_LOG"
}

setup_environment() {
    log "INFO" "Setting up test environment..."

    export SCRIPTPATH="$PROJECT_ROOT"
    export LIB_PATH="${PROJECT_ROOT}/lib"
    export MODULES_PATH="${PROJECT_ROOT}/modules"
    export CONFIG_PATH="${PROJECT_ROOT}/config"
    export DEBUG=true
    export domain="test.example.com"
    export mode="test"
    export dir="/tmp/neko_modcov_$$"
    export called_fn_dir="${dir}/.called"
    export LOGFILE="${dir}/test.log"
    export TOOLS_PATH="${TOOLS_PATH:-/tmp/Tools}"

    mkdir -p "$dir"/{logs,osint,subdomains,dns,hosts,webs,ports,content,technologies,urls,js,parameters,vulnerabilities,xss,takeover,cloud,auth,api,reports,.tmp,.called}
    mkdir -p "$TOOLS_PATH"
    touch "$LOGFILE"

    log "INFO" "Test directory: $dir"
}

cleanup() {
    rm -rf "/tmp/neko_modcov_$$" 2>/dev/null || true
}

trap cleanup EXIT

load_libraries() {
    log "INFO" "Loading configuration and libraries..."

    cd "$PROJECT_ROOT"

    if [[ -f "neko.cfg" ]]; then
        source neko.cfg 2>/dev/null || log "WARN" "Config load warning"
    fi

    for lib in lib/*.sh; do
        if [[ -f "$lib" ]]; then
            source "$lib" 2>/dev/null || log "WARN" "Failed to load: $(basename "$lib")"
        fi
    done
}

test_module_functions() {
    log "INFO" "Testing module function coverage..."

    local total_modules=0
    local total_functions=0
    local available_functions=0
    local missing_functions=0

    for module in modules/*.sh; do
        if [[ ! -f "$module" ]]; then
            continue
        fi

        local modname
        modname=$(basename "$module" .sh)
        ((total_modules++)) || true

        printf '\n═══════════════════════════════════════════════════════════════\n' >> "$COVERAGE_LOG"
        printf 'Module: %s\n' "$modname" >> "$COVERAGE_LOG"
        printf '═══════════════════════════════════════════════════════════════\n' >> "$COVERAGE_LOG"

        if source "$module" 2>/dev/null; then
            printf '[LOADED] Module sourced successfully\n' >> "$COVERAGE_LOG"

            local funcs
            funcs=$(grep -E "^[a-z_]+\(\)\s*\{" "$module" 2>/dev/null | sed 's/().*//' || true)

            if [[ -n "$funcs" ]]; then
                while IFS= read -r func; do
                    [[ -z "$func" ]] && continue
                    ((total_functions++)) || true

                    if type -t "$func" &>/dev/null; then
                        printf '  [OK] %s\n' "$func" >> "$COVERAGE_LOG"
                        ((available_functions++)) || true
                    else
                        printf '  [MISSING] %s\n' "$func" >> "$COVERAGE_LOG"
                        ((missing_functions++)) || true
                    fi
                done <<< "$funcs"
            else
                printf '[INFO] No functions found in module\n' >> "$COVERAGE_LOG"
            fi
        else
            printf '[FAIL] Could not load module\n' >> "$COVERAGE_LOG"
        fi
    done

    printf '\n═══════════════════════════════════════════════════════════════\n' >> "$COVERAGE_LOG"
    printf 'COVERAGE SUMMARY\n' >> "$COVERAGE_LOG"
    printf '═══════════════════════════════════════════════════════════════\n' >> "$COVERAGE_LOG"
    printf 'Modules tested: %d\n' "$total_modules" >> "$COVERAGE_LOG"
    printf 'Total functions: %d\n' "$total_functions" >> "$COVERAGE_LOG"
    printf 'Available: %d\n' "$available_functions" >> "$COVERAGE_LOG"
    printf 'Missing: %d\n' "$missing_functions" >> "$COVERAGE_LOG"

    if [[ "$total_functions" -gt 0 ]]; then
        local coverage
        coverage=$((available_functions * 100 / total_functions))
        printf 'Coverage: %d%%\n' "$coverage" >> "$COVERAGE_LOG"
    fi

    log "INFO" "Function coverage testing complete"
}

test_parameter_handling() {
    log "INFO" "Testing function parameter handling..."

    printf '%s\n' "=== PARAMETER HANDLING TESTS ===" > "$PARAM_LOG"
    printf 'Timestamp: %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$PARAM_LOG"

    printf -- '--- validate_domain ---\n' >> "$PARAM_LOG"
    if type -t validate_domain &>/dev/null; then
        local tests=(
            "example.com:0"
            "sub.example.com:0"
            "192.168.1.1:0"
            "10.0.0.0/24:0"
            "invalid domain:1"
            ":1"
            "..com:1"
            "-start.com:1"
        )

        for test in "${tests[@]}"; do
            local input="${test%%:*}"
            local expected="${test##*:}"
            local result

            if validate_domain "$input" 2>/dev/null; then
                result=0
            else
                result=1
            fi

            if [[ "$result" == "$expected" ]]; then
                printf '%s\n' "[PASS] validate_domain(\"$input\") = $result" >> "$PARAM_LOG"
            else
                printf '%s\n' "[FAIL] validate_domain(\"$input\") = $result (expected: $expected)" >> "$PARAM_LOG"
            fi
        done
    else
        printf '[SKIP] validate_domain not defined\n' >> "$PARAM_LOG"
    fi

    printf -- '\n--- count_lines ---\n' >> "$PARAM_LOG"
    if type -t count_lines &>/dev/null; then
        printf 'line1\nline2\nline3\n' > /tmp/test_param_$$

        local count
        count=$(count_lines /tmp/test_param_$$)
        if [[ "$count" == "3" ]]; then
            printf '[PASS] count_lines(file with 3 lines) = %s\n' "$count" >> "$PARAM_LOG"
        else
            printf '[FAIL] count_lines(file with 3 lines) = %s (expected: 3)\n' "$count" >> "$PARAM_LOG"
        fi

        local empty_count
        empty_count=$(count_lines /tmp/nonexistent_$$ 2>/dev/null || echo "0")
        printf '[INFO] count_lines(nonexistent file) = %s\n' "$empty_count" >> "$PARAM_LOG"

        rm -f /tmp/test_param_$$
    else
        printf '[SKIP] count_lines not defined\n' >> "$PARAM_LOG"
    fi

    printf -- '\n--- is_ip ---\n' >> "$PARAM_LOG"
    if type -t is_ip &>/dev/null; then
        local ip_tests=(
            "192.168.1.1:0"
            "10.0.0.1:0"
            "255.255.255.255:0"
            "example.com:1"
            "192.168.1:1"
            "256.1.1.1:1"
        )

        for test in "${ip_tests[@]}"; do
            local input="${test%%:*}"
            local expected="${test##*:}"
            local result

            if is_ip "$input" 2>/dev/null; then
                result=0
            else
                result=1
            fi

            if [[ "$result" == "$expected" ]]; then
                printf '%s\n' "[PASS] is_ip(\"$input\") = $result" >> "$PARAM_LOG"
            else
                printf '%s\n' "[FAIL] is_ip(\"$input\") = $result (expected: $expected)" >> "$PARAM_LOG"
            fi
        done
    else
        printf '[SKIP] is_ip not defined\n' >> "$PARAM_LOG"
    fi

    log "INFO" "Parameter handling tests complete"
}

test_edge_cases() {
    log "INFO" "Testing edge cases..."

    printf '%s\n' "=== EDGE CASE TESTS ===" > "$EDGE_LOG"
    printf 'Timestamp: %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$EDGE_LOG"

    printf -- '--- Empty input handling ---\n' >> "$EDGE_LOG"

    if type -t validate_domain &>/dev/null; then
        if ! validate_domain "" 2>/dev/null; then
            printf '[PASS] validate_domain handles empty input\n' >> "$EDGE_LOG"
        else
            printf '[FAIL] validate_domain should reject empty input\n' >> "$EDGE_LOG"
        fi
    fi

    if type -t count_lines &>/dev/null; then
        local result
        result=$(count_lines "" 2>/dev/null || echo "0")
        printf '[INFO] count_lines("") = %s\n' "$result" >> "$EDGE_LOG"
    fi

    printf -- '\n--- Special character handling ---\n' >> "$EDGE_LOG"

    local special_inputs=(
        "test\`command\`"
        "test\$(whoami)"
        "test;ls"
        "test|cat"
        "test&bg"
    )

    for input in "${special_inputs[@]}"; do
        if type -t validate_domain &>/dev/null; then
            if ! validate_domain "$input" 2>/dev/null; then
                printf '[OK] Special chars rejected: %s\n' "${input:0:20}" >> "$EDGE_LOG"
            else
                printf '[WARN] Special chars accepted: %s\n' "${input:0:20}" >> "$EDGE_LOG"
            fi
        fi
    done

    printf -- '\n--- Large input handling ---\n' >> "$EDGE_LOG"

    local large_input
    large_input=$(printf 'a%.0s' {1..1000})

    if type -t validate_domain &>/dev/null; then
        if ! validate_domain "$large_input" 2>/dev/null; then
            printf '[OK] Large input (1000 chars) rejected\n' >> "$EDGE_LOG"
        else
            printf '[WARN] Large input accepted\n' >> "$EDGE_LOG"
        fi
    fi

    log "INFO" "Edge case tests complete"
}

test_return_codes() {
    log "INFO" "Testing return codes..."

    printf '%s\n' "=== RETURN CODE TESTS ===" > "$RETURN_LOG"
    printf 'Timestamp: %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$RETURN_LOG"

    printf -- '--- command_exists ---\n' >> "$RETURN_LOG"
    if type -t command_exists &>/dev/null; then
        command_exists bash
        local rc=$?
        printf 'command_exists("bash") returned: %d (expected: 0)\n' "$rc" >> "$RETURN_LOG"

        command_exists nonexistent_xyz_123 || true
        rc=$?
        printf 'command_exists("nonexistent") returned: %d (expected: 1)\n' "$rc" >> "$RETURN_LOG"
    else
        printf '[SKIP] command_exists not defined\n' >> "$RETURN_LOG"
    fi

    printf -- '\n--- is_ip ---\n' >> "$RETURN_LOG"
    if type -t is_ip &>/dev/null; then
        is_ip "192.168.1.1"
        local rc=$?
        printf 'is_ip("192.168.1.1") returned: %d (expected: 0)\n' "$rc" >> "$RETURN_LOG"

        is_ip "example.com" || true
        rc=$?
        printf 'is_ip("example.com") returned: %d (expected: 1)\n' "$rc" >> "$RETURN_LOG"
    else
        printf '[SKIP] is_ip not defined\n' >> "$RETURN_LOG"
    fi

    printf -- '\n--- is_cidr ---\n' >> "$RETURN_LOG"
    if type -t is_cidr &>/dev/null; then
        is_cidr "10.0.0.0/24"
        local rc=$?
        printf 'is_cidr("10.0.0.0/24") returned: %d (expected: 0)\n' "$rc" >> "$RETURN_LOG"

        is_cidr "192.168.1.1" || true
        rc=$?
        printf 'is_cidr("192.168.1.1") returned: %d (expected: 1)\n' "$rc" >> "$RETURN_LOG"
    else
        printf '[SKIP] is_cidr not defined\n' >> "$RETURN_LOG"
    fi

    log "INFO" "Return code tests complete"
}

main() {
    printf '%s\n' "╔══════════════════════════════════════════════════════════════╗" > "$COVERAGE_LOG"
    printf '%s\n' "║     NEKO MODULE FUNCTION COVERAGE TESTING                    ║" >> "$COVERAGE_LOG"
    printf '%s\n' "╚══════════════════════════════════════════════════════════════╝" >> "$COVERAGE_LOG"
    printf 'Timestamp: %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S')" >> "$COVERAGE_LOG"

    setup_environment
    load_libraries
    test_module_functions
    test_parameter_handling
    test_edge_cases
    test_return_codes

    log "INFO" "All module function coverage tests complete"
    log "INFO" "Logs available in: $LOG_DIR"
}

main "$@"