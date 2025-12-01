#!/usr/bin/env bash
################################################################################
# NEKO SYNTAX VALIDATION SCRIPT
# ============================================================================
# This script validates bash script syntax with proper error handling.
# It is designed to be run from GitHub Actions workflows.
################################################################################

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/logs/syntax"

# Create log directory
mkdir -p "$LOG_DIR"

# Log files
readonly SYNTAX_LOG="${LOG_DIR}/bash_syntax_results.log"
readonly ERROR_LOG="${LOG_DIR}/bash_syntax_errors.log"
readonly DETAILED_LOG="${LOG_DIR}/bash_syntax_detailed.log"

# Safe logging function
log() {
    local level="$1"
    shift
    local message="$*"
    printf '[%s] %s\n' "$level" "$message" | tee -a "$SYNTAX_LOG"
}

log_to_file() {
    printf '%s\n' "$*" >> "$DETAILED_LOG"
}

# Initialize logs
init_logs() {
    printf '%s\n' "========================================"  > "$SYNTAX_LOG"
    printf '%s\n' "NEKO BASH SYNTAX VALIDATION"            >> "$SYNTAX_LOG"
    printf '%s\n' "========================================"  >> "$SYNTAX_LOG"
    printf '%s\n' "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')" >> "$SYNTAX_LOG"
    printf '%s\n' "Project Root: $PROJECT_ROOT"             >> "$SYNTAX_LOG"
    printf '%s\n' ""                                         >> "$SYNTAX_LOG"
    
    : > "$ERROR_LOG"
    : > "$DETAILED_LOG"
}

# Validate all bash scripts
validate_scripts() {
    local total=0
    local passed=0
    local failed=0
    local warnings=0
    
    log "INFO" "Validating bash script syntax..."
    log_to_file ""
    log_to_file "=== Script Validation ==="
    
    cd "$PROJECT_ROOT"
    
    # Find all shell scripts
    while IFS= read -r script; do
        ((total++))
        
        log_to_file ""
        log_to_file "--- Script: $script ---"
        
        # Get file info
        local size lines
        size=$(wc -c < "$script" 2>/dev/null || echo "0")
        lines=$(wc -l < "$script" 2>/dev/null || echo "0")
        log_to_file "Size: $size bytes, Lines: $lines"
        
        # Check syntax with bash -n
        local syntax_err_file="/tmp/syntax_err_$$_$(basename "$script")"
        if bash -n "$script" 2>"$syntax_err_file"; then
            log "PASS" "$script"
            log_to_file "Status: VALID"
            ((passed++))
        else
            log "FAIL" "$script"
            log_to_file "Status: INVALID"
            
            # Log errors
            printf '\n[ERROR] %s:\n' "$script" >> "$ERROR_LOG"
            cat "$syntax_err_file" >> "$ERROR_LOG"
            log_to_file "Error Details:"
            cat "$syntax_err_file" >> "$DETAILED_LOG"
            
            ((failed++))
        fi
        rm -f "$syntax_err_file"
        
        # Check for common issues (warnings only)
        if grep -qE '\[ \$[A-Za-z_][A-Za-z0-9_]* ' "$script" 2>/dev/null; then
            log_to_file "Warning: Potential unquoted variable in test"
            ((warnings++))
        fi
        
    done < <(find . -name "*.sh" -type f ! -path "./.git/*" 2>/dev/null)
    
    log_to_file ""
    log_to_file "========================================"
    log "INFO" "Syntax Validation Summary:"
    log "INFO" "  Total Scripts: $total"
    log "INFO" "  Passed: $passed"
    log "INFO" "  Failed: $failed"
    log "INFO" "  Warnings: $warnings"
    log_to_file "========================================"
    
    # Set outputs for GitHub Actions
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
        printf 'total=%d\n' "$total" >> "$GITHUB_OUTPUT"
        printf 'passed=%d\n' "$passed" >> "$GITHUB_OUTPUT"
        printf 'failed=%d\n' "$failed" >> "$GITHUB_OUTPUT"
    fi
    
    # Return failure if any syntax errors
    if [[ $failed -gt 0 ]]; then
        log "ERROR" "$failed scripts have syntax errors"
        printf '\n%s\n' "=== Syntax Errors ==="
        cat "$ERROR_LOG"
        return 1
    fi
    
    return 0
}

# Run ShellCheck analysis
run_shellcheck() {
    local shellcheck_log="${LOG_DIR}/shellcheck_results.log"
    
    # Check if shellcheck is available
    if ! command -v shellcheck &>/dev/null; then
        log "SKIP" "ShellCheck not installed"
        return 0
    fi
    
    log "INFO" "Running ShellCheck analysis..."
    
    printf '%s\n' "========================================"  > "$shellcheck_log"
    printf '%s\n' "SHELLCHECK ANALYSIS"                     >> "$shellcheck_log"
    printf '%s\n' "========================================"  >> "$shellcheck_log"
    printf '%s\n' "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')" >> "$shellcheck_log"
    printf '%s\n' ""                                         >> "$shellcheck_log"
    
    local issues=0
    
    cd "$PROJECT_ROOT"
    
    while IFS= read -r script; do
        printf '\n--- %s ---\n' "$script" >> "$shellcheck_log"
        
        if shellcheck -f gcc "$script" >> "$shellcheck_log" 2>&1; then
            printf '  [OK] No issues\n' >> "$shellcheck_log"
        else
            ((issues++))
        fi
    done < <(find . -name "*.sh" -type f ! -path "./.git/*" 2>/dev/null)
    
    # Count issues by severity
    local error_count warn_count note_count
    error_count=$(grep -c ":error:" "$shellcheck_log" 2>/dev/null || echo "0")
    warn_count=$(grep -c ":warning:" "$shellcheck_log" 2>/dev/null || echo "0")
    note_count=$(grep -c ":note:" "$shellcheck_log" 2>/dev/null || echo "0")
    
    log "INFO" "ShellCheck Summary:"
    log "INFO" "  Errors: $error_count"
    log "INFO" "  Warnings: $warn_count"
    log "INFO" "  Notes: $note_count"
    
    return 0
}

# Main
main() {
    init_logs
    
    local exit_code=0
    
    if ! validate_scripts; then
        exit_code=1
    fi
    
    run_shellcheck || true
    
    log "INFO" "Validation complete. Logs available in: $LOG_DIR"
    
    return $exit_code
}

main "$@"
