#!/usr/bin/env bash
################################################################################
# NEKO STRUCTURE VALIDATION SCRIPT
# ============================================================================
# This script validates project structure with proper error handling.
# It is designed to be run from GitHub Actions workflows.
################################################################################

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/logs/structure"

# Create log directory
mkdir -p "$LOG_DIR"

# Log files
readonly STRUCT_LOG="${LOG_DIR}/structure_validation.log"

# Safe logging function
log() {
    local level="$1"
    shift
    local message="$*"
    printf '[%s] %s\n' "$level" "$message" | tee -a "$STRUCT_LOG"
}

log_to_file() {
    printf '%s\n' "$*" >> "$STRUCT_LOG"
}

# Initialize logs
init_logs() {
    printf '%s\n' "========================================"  > "$STRUCT_LOG"
    printf '%s\n' "NEKO PROJECT STRUCTURE VALIDATION"      >> "$STRUCT_LOG"
    printf '%s\n' "========================================"  >> "$STRUCT_LOG"
    printf '%s\n' "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')" >> "$STRUCT_LOG"
    printf '%s\n' "Project Root: $PROJECT_ROOT"             >> "$STRUCT_LOG"
    printf '%s\n' ""                                         >> "$STRUCT_LOG"
}

# Validate directories
validate_directories() {
    local -a required_dirs=(
        "modules"
        "lib"
        "config"
        "plugins"
    )
    
    local missing=0
    
    log "INFO" "Validating required directories..."
    log_to_file ""
    log_to_file "=== Required Directories ==="
    
    cd "$PROJECT_ROOT"
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local count
            count=$(find "$dir" -type f 2>/dev/null | wc -l)
            log "PASS" "$dir/ ($count files)"
        else
            log "FAIL" "$dir/ is missing"
            ((missing++))
        fi
    done
    
    return $missing
}

# Validate files
validate_files() {
    local -a required_files=(
        "neko.sh"
        "neko.cfg"
        "install.sh"
        "README.md"
    )
    
    local missing=0
    
    log "INFO" "Validating required files..."
    log_to_file ""
    log_to_file "=== Required Files ==="
    
    cd "$PROJECT_ROOT"
    
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            local lines size
            lines=$(wc -l < "$file" 2>/dev/null || echo "0")
            size=$(wc -c < "$file" 2>/dev/null || echo "0")
            log "PASS" "$file ($lines lines, $size bytes)"
        else
            log "FAIL" "$file is missing"
            ((missing++))
        fi
    done
    
    return $missing
}

# Validate modules
validate_modules() {
    local -a expected_modules=(
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
    
    local missing=0
    
    log "INFO" "Validating expected modules..."
    log_to_file ""
    log_to_file "=== Expected Modules ==="
    
    cd "$PROJECT_ROOT"
    
    for module in "${expected_modules[@]}"; do
        if [[ -f "modules/$module" ]]; then
            local lines
            lines=$(wc -l < "modules/$module" 2>/dev/null || echo "0")
            log "PASS" "modules/$module ($lines lines)"
        else
            log "WARN" "modules/$module is missing"
            ((missing++))
        fi
    done
    
    return 0  # Don't fail on missing modules, just warn
}

# Validate libraries
validate_libraries() {
    local -a expected_libs=(
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
    
    local missing=0
    
    log "INFO" "Validating expected libraries..."
    log_to_file ""
    log_to_file "=== Expected Libraries ==="
    
    cd "$PROJECT_ROOT"
    
    for lib in "${expected_libs[@]}"; do
        if [[ -f "lib/$lib" ]]; then
            local lines
            lines=$(wc -l < "lib/$lib" 2>/dev/null || echo "0")
            log "PASS" "lib/$lib ($lines lines)"
        else
            log "WARN" "lib/$lib is missing"
            ((missing++))
        fi
    done
    
    return 0  # Don't fail on missing libraries, just warn
}

# Generate directory tree
generate_tree() {
    log "INFO" "Generating directory tree..."
    log_to_file ""
    log_to_file "=== Complete Directory Tree ==="
    
    cd "$PROJECT_ROOT"
    
    if command -v tree &>/dev/null; then
        tree -a -I '.git' --noreport . >> "$STRUCT_LOG" 2>/dev/null || true
    else
        find . -not -path './.git/*' -type f 2>/dev/null | sort >> "$STRUCT_LOG"
    fi
}

# Main
main() {
    init_logs
    
    local dir_missing=0
    local file_missing=0
    
    validate_directories || dir_missing=$?
    validate_files || file_missing=$?
    validate_modules
    validate_libraries
    generate_tree
    
    log_to_file ""
    log_to_file "========================================"
    log "INFO" "Structure Validation Summary:"
    log "INFO" "  Missing Directories: $dir_missing"
    log "INFO" "  Missing Files: $file_missing"
    log_to_file "========================================"
    
    log "INFO" "Validation complete. Logs available in: $LOG_DIR"
    
    # Fail only if critical directories or files are missing
    if [[ $dir_missing -gt 0 ]] || [[ $file_missing -gt 0 ]]; then
        log "ERROR" "Critical structure issues found"
        return 1
    fi
    
    return 0
}

main "$@"
