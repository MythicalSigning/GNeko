# Neko Bug Bounty Framework

## Overview
Neko is a comprehensive Bash-based bug bounty automation framework. It provides an end-to-end reconnaissance and vulnerability scanning pipeline with 18 specialized modules covering OSINT, subdomain discovery, DNS analysis, web probing, port scanning, content discovery, fingerprinting, URL analysis, parameter discovery, vulnerability scanning, XSS detection, subdomain takeover, cloud security, authentication testing, API security, and more.

**Project Type:** CLI Tool (Command Line Interface)
**Language:** Bash/Shell Script
**Current State:** Active development with comprehensive testing suite

## Project Structure

```
neko/
├── neko.sh              # Main entry point script
├── neko.cfg             # Configuration file
├── install.sh           # Installation script
├── run_tests.sh         # Comprehensive test suite
├── test_discord.sh      # Discord notification tests
├── modules/             # 18 scanning phase modules
│   ├── 00_osint.sh      # OSINT & Intelligence gathering
│   ├── 01_subdomain.sh  # Subdomain discovery
│   ├── 02_dns.sh        # DNS analysis
│   ├── 03_webprobe.sh   # Web probing
│   ├── 04_portscan.sh   # Port scanning
│   ├── 05_content.sh    # Content discovery
│   ├── 06_fingerprint.sh # Technology fingerprinting
│   ├── 07_urlanalysis.sh # URL analysis
│   ├── 08_params.sh     # Parameter discovery
│   ├── 09_vulnscan.sh   # Vulnerability scanning
│   ├── 10_xss.sh        # XSS detection
│   ├── 11_takeover.sh   # Subdomain takeover
│   ├── 12_cloud.sh      # Cloud security
│   ├── 13_auth.sh       # Authentication testing
│   ├── 14_api.sh        # API security
│   ├── 15_report.sh     # Report generation
│   ├── 16_advanced_vulns.sh # Advanced vulnerabilities
│   └── 17_bettercap.sh  # Bettercap integration
├── lib/                 # Core libraries
│   ├── core.sh          # Core utilities
│   ├── logging.sh       # v2.2 logging system
│   ├── discord_notifications.sh # Discord integration
│   ├── parallel.sh      # Parallel processing
│   ├── async_pipeline.sh # Async pipeline
│   ├── queue_manager.sh # Queue management
│   ├── data_flow_bus.sh # Data flow bus
│   ├── orchestrator.sh  # Orchestration
│   ├── error_handling.sh # Error handling
│   ├── error_reporting.sh # Error reporting
│   ├── proxy_rotation.sh # Proxy rotation
│   ├── intelligence.sh  # Intelligence engine
│   └── plugin.sh        # Plugin system
├── config/              # Configuration files
│   └── plugins.json     # Plugin configuration
├── plugins/             # Plugin directory
└── .github/workflows/   # GitHub Actions workflows
    ├── neko-deep-error-detection.yml      # Deep error detection
    └── neko-comprehensive-testing.yml     # Comprehensive testing
```

## GitHub Actions Testing

The project includes comprehensive GitHub Actions workflows for testing:

### neko-comprehensive-testing.yml
Tests everything from installation through all features with extremely detailed logging:
- Deep syntax analysis with ShellCheck
- Configuration validation
- File structure validation
- Library loading tests
- Module loading tests
- Main script command tests
- Installation simulation
- Test suite execution

### neko-deep-error-detection.yml
Original deep error detection workflow covering:
- Syntax validation
- Configuration parsing
- Structure verification
- Library and module loading
- API key validation

## Usage

### Basic Scan
```bash
./neko.sh -d example.com
```

### Show Help
```bash
./neko.sh --help
```

### Check Tools
```bash
./neko.sh --check-tools
```

### Run Tests Locally
```bash
./run_tests.sh
```

## Testing Approach

The GitHub Actions workflows are designed to:
1. Test all framework components without performing actual scans
2. Exclude notification tests (Discord/Slack/Telegram)
3. Exclude external API connectivity tests
4. Provide extremely detailed logging for debugging
5. Generate downloadable artifacts with comprehensive logs

## Recent Changes
- 2025-12-01: Fixed neko.cfg SCRIPTPATH unbound variable issue for standalone config loading
- 2025-12-01: Set up Replit environment with console workflow for CLI tool
- 2025-12-01: Added .gitignore for proper file exclusions
- 2025-01-XX: Added neko-comprehensive-testing.yml workflow for extended testing coverage
- Enhanced logging system for better debugging in CI/CD environments

## Replit Environment
This project runs as a CLI tool in Replit. The workflow is configured to show help by default.

To run scans, use the Shell and execute commands like:
```bash
./neko.sh -d example.com
./neko.sh --check-tools
```

Note: Most security tools require separate installation. Run `./install.sh` for full setup.

## User Preferences
- Focus on comprehensive testing coverage
- Detailed logging for debugging
- No actual scanning or notification testing in CI/CD
- All logs preserved as artifacts for review

## Key Features
- v2.2 Logging System with detailed output
- Discord/Slack/Telegram notification support
- Parallel processing with queue management
- Data flow orchestration
- Plugin architecture
- Proxy rotation support
- Intelligence-based scanning
