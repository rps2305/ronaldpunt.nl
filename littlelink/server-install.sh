#!/usr/bin/env bash
###############################################################################
# Linux Server Installation Script
# - Development tools
# - SEO tooling
# - Security utilities
#
# Continues even if individual packages are unavailable.
# Supports: Ubuntu, Debian, ZorinOS (x86_64 and ARM64)
###############################################################################

set -euo pipefail

readonly SCRIPT_VERSION="1.0.0"
FAILED_PACKAGES=()
INSTALL_LOG="/tmp/install-$(date +%Y%m%d-%H%M%S).log"

log_info() { echo "[INFO] $*"; }
log_warn() { echo "[WARN] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }
log_success() { echo "[OK] $*"; }

log_info "Linux Server Installation Script v${SCRIPT_VERSION}"
log_info "Log file: ${INSTALL_LOG}"
log_info "Architecture: $(uname -m)"

install_package() {
    local package="$1"
    local description="${2:-}"
    local result

    if [[ -n "$description" ]]; then
        echo -n "Installing ${package} (${description})... "
    else
        echo -n "Installing ${package}... "
    fi

    result=$(apt-get install -y "$package" 2>&1)
    local exit_code=$?

    if echo "$result" | grep -qi "package.*not found\|unable to locate\|no such package"; then
        echo "SKIPPED (not available)"
        log_warn "${package}: not available in repositories"
        FAILED_PACKAGES+=("${package}:not_found")
        return 0
    fi

    if [[ $exit_code -eq 0 ]]; then
        echo "OK"
        return 0
    fi

    if echo "$result" | grep -qi "already the newest version"; then
        echo "OK (already installed)"
        return 0
    fi

    echo "FAILED"
    log_error "${package}: installation failed (exit ${exit_code})"
    FAILED_PACKAGES+=("${package}:failed")
    return 0
}

install_packages_robust() {
    local packages=("$@")
    local pkg
    local description

    for item in "${packages[@]}"; do
        pkg="${item%%:*}"
        description="${item##*:}"

        if [[ "$pkg" == "$description" ]] || [[ -z "$description" ]] || [[ "$description" =~ ^[[:space:]]*$ ]]; then
            description=""
        fi

        install_package "$pkg" "$description"
    done
}

detect_architecture() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64) echo "x86_64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l) echo "armhf" ;;
        *) echo "$arch" ;;
    esac
}

update_system() {
    log_info "Updating package lists..."
    apt-get update -y >> "${INSTALL_LOG}" 2>&1
    if [[ $? -eq 0 ]]; then
        log_success "Package lists updated"
    else
        log_warn "Failed to update package lists"
    fi
}

###############################################################################
# Core system utilities
###############################################################################
install_core_utilities() {
    log_info "Installing core utilities..."

    install_packages_robust \
        "ca-certificates:SSL certificates" \
        "curl:HTTP client" \
        "wget:Download tool" \
        "gnupg:Encryption" \
        "ls-release:Distribution info" \
        "software-properties-common:PPA support" \
        "build-essential:Compiler tools" \
        "unzip:Archive extraction" \
        "zip:Archive creation" \
        "p7zip-full:7-Zip support" \
        "tar:Archive handling" \
        "rsync:File sync" \
        "tree:Directory tree" \
        "htop:Process monitor" \
        "btop:Resource monitor" \
        "tmux:Terminal multiplexer" \
        "screen:Terminal multiplexer" \
        "jq:JSON processor" \
        "yq:YAML processor" \
        "entr:File watcher" \
        "inxi:System info" \
        "neovim:Text editor" \
        "vim:Text editor" \
        "nano:Text editor" \
        "git:Version control" \
        "git-lfs:Large file support" \
        "make:Build tool" \
        "cmake:Build tool"
}

###############################################################################
# Development tools
###############################################################################
install_dev_tools() {
    log_info "Installing development tools..."

    install_packages_robust \
        "python3:Python 3 runtime" \
        "python3-venv:Virtual environments" \
        "python3-pip:Python package manager" \
        "python3-dev:Python development headers" \
        "python3-requests:HTTP library" \
        "python3-yaml:YAML library" \
        "python3-json:JSON library" \
        "python3-lxml:XML library" \
        "python3-beautifulsoup4:HTML parsing" \
        "python3-selenium:Browser automation" \
        "python3-scrapy:Web scraping" \
        "golang-go:Go language" \
        "rustc:Rust compiler" \
        "cargo:Rust package manager" \
        "nodejs:Node.js runtime" \
        "npm:Node package manager" \
        "yarn:Yarn package manager" \
        "docker.io:Docker runtime" \
        "docker-compose:Docker orchestration" \
        "kubectl:Kubernetes CLI" \
        "helm:Kubernetes package manager" \
        "k9s:Kubernetes terminal UI" \
        "terraform:Infrastructure as code" \
        "ansible:Automation tool" \
        "openssh-client:SSH client" \
        "openssh-server:SSH server" \
        "sshpass:SSH password automation" \
        "mosh:Mobile shell" \
        "httpie:REST client" \
        "curl:HTTP client" \
        "whois:WHOIS client" \
        "dnsutils:DNS tools" \
        "iputils-ping:ping utility" \
        "traceroute:Network diagnostic" \
        "mtr:Network diagnostic" \
        "net-tools:Network utilities" \
        "ethtool:Network device tool"
}

###############################################################################
# SEO tooling
###############################################################################
install_seo_tools() {
    log_info "Installing SEO tools..."

    install_packages_robust \
        "ripgrep:Fast text search" \
        "fd-find:Fast file search" \
        "thefuck:Command correction" \
        "links:Text-mode browser" \
        "lynx:Text-mode browser" \
        "w3m:Text-mode browser" \
        "curl:HTTP client" \
        "httpie:REST client" \
        "jq:JSON processor" \
        "yq:YAML processor" \
        "sitemap-html:HTML sitemap generator" \
        "metaclean:Metadata cleaner" \
        "python3-requests:HTTP library" \
        "python3-beautifulsoup4:HTML parsing" \
        "python3-lxml:XML library" \
        "python3-cssselect:CSS selector" \
        "python3-urllib3:HTTP library"
}

###############################################################################
# Security utilities
###############################################################################
install_security_tools() {
    log_info "Installing security tools..."

    local skip_tripwire=false
    local arch
    arch=$(uname -m)
    if [[ "$arch" == "aarch64" ]] || [[ "$arch" == "arm64" ]]; then
        log_warn "TripWire skipped on ARM64 (known compatibility issues on Raspberry Pi)"
        skip_tripwire=true
    fi

    if [[ "$skip_tripwire" == "true" ]]; then
        install_packages_robust \
            "nmap:Network scanner" \
            "netcat-openbsd:Network utility" \
            "socat:Network utility" \
            "tcpdump:Packet analyzer" \
            "tshark:Packet analyzer" \
            "wireshark-common:Packet analyzer GUI" \
            "sslscan:SSL scanner" \
            "testssl:SSL testing" \
            "openssl:Cryptography" \
            "gnupg:GPG encryption" \
            "pass:Password manager" \
            "gpg:GPG encryption" \
            "hashcat:Password cracker" \
            "john:Password cracker" \
            "hydra:Password brute-force" \
            "medusa:Password brute-force" \
            "burp-suite:Web security testing" \
            "zap:Web security testing" \
            "sqlmap:SQL injection" \
            "nikto:Web server scanner" \
            "dirb:Directory scanner" \
            "gobuster:Directory scanner" \
            "wfuzz:Fuzzer" \
            "aircrack-ng:Wireless auditing" \
            "metasploit-framework:Penetration testing" \
            "exploitdb:Exploit database" \
            "smbclient:SMB client" \
            "smbmap:SMB enumeration" \
            "enum4linux:Linux enum" \
            "nessus:Full scan" \
            "openvpn:VPN client" \
            "wireguard:VPN client" \
            "ufw:Firewall" \
            "iptables:Firewall" \
            "fail2ban:Intrusion prevention" \
            "rkhunter:Rootkit detection" \
            "chkrootkit:Rootkit detection" \
            "lynis:Security audit" \
            "auditd:Audit daemon" \
            "aide:File integrity (ARM64 compatible)" \
            "clamav:Antivirus" \
            "clamav-daemon:Antivirus daemon" \
            "spamassassin:Spam filtering" \
            "blacklist:Blacklist tools" \
            "apparmor:Mandatory access control" \
            "selinux-utils:SELinux tools" \
            "acct:Process accounting" \
            "nfs-kernel-server:NFS server" \
            "samba:SMB file sharing"
    else
        install_packages_robust \
            "nmap:Network scanner" \
            "netcat-openbsd:Network utility" \
            "socat:Network utility" \
            "tcpdump:Packet analyzer" \
            "tshark:Packet analyzer" \
            "wireshark-common:Packet analyzer GUI" \
            "sslscan:SSL scanner" \
            "testssl:SSL testing" \
            "openssl:Cryptography" \
            "gnupg:GPG encryption" \
            "pass:Password manager" \
            "gpg:GPG encryption" \
            "hashcat:Password cracker" \
            "john:Password cracker" \
            "hydra:Password brute-force" \
            "medusa:Password brute-force" \
            "burp-suite:Web security testing" \
            "zap:Web security testing" \
            "sqlmap:SQL injection" \
            "nikto:Web server scanner" \
            "dirb:Directory scanner" \
            "gobuster:Directory scanner" \
            "wfuzz:Fuzzer" \
            "aircrack-ng:Wireless auditing" \
            "metasploit-framework:Penetration testing" \
            "exploitdb:Exploit database" \
            "smbclient:SMB client" \
            "smbmap:SMB enumeration" \
            "enum4linux:Linux enum" \
            "nessus:Full scan" \
            "openvpn:VPN client" \
            "wireguard:VPN client" \
            "ufw:Firewall" \
            "iptables:Firewall" \
            "fail2ban:Intrusion prevention" \
            "rkhunter:Rootkit detection" \
            "chkrootkit:Rootkit detection" \
            "lynis:Security audit" \
            "auditd:Audit daemon" \
            "aide:File integrity" \
            "tripwire:File integrity" \
            "clamav:Antivirus" \
            "clamav-daemon:Antivirus daemon" \
            "spamassassin:Spam filtering" \
            "blacklist:Blacklist tools" \
            "apparmor:Mandatory access control" \
            "selinux-utils:SELinux tools" \
            "acct:Process accounting" \
            "nfs-kernel-server:NFS server" \
            "samba:SMB file sharing"
    fi
}

###############################################################################
# Web server & database tools
###############################################################################
install_web_tools() {
    log_info "Installing web server and database tools..."

    install_packages_robust \
        "apache2:Web server" \
        "nginx:Web server" \
        "mariadb-server:Database server" \
        "mariadb-client:Database client" \
        "postgresql:Database server" \
        "postgresql-client:Database client" \
        "redis-server:Cache server" \
        "memcached:Cache server" \
        "rabbitmq-server:Message queue" \
        "elasticsearch:Search engine" \
        "kibana:Data visualization" \
        "grafana:Monitoring dashboard" \
        "prometheus:Monitoring system" \
        "node-exporter:Metrics exporter" \
        "caddy:Web server" \
        "php:PHP runtime" \
        "php-fpm:PHP FastCGI" \
        "php-cli:PHP CLI" \
        "php-mysql:PHP MySQL" \
        "php-pgsql:PHP PostgreSQL" \
        "php-curl:PHP cURL" \
        "php-xml:PHP XML" \
        "php-mbstring:PHP mbstring" \
        "php-json:PHP JSON" \
        "php-zip:PHP ZIP" \
        "php-gd:PHP GD" \
        "php-bcmath:PHP bcmath"
}

###############################################################################
# Monitoring & logging
###############################################################################
install_monitoring_tools() {
    log_info "Installing monitoring and logging tools..."

    local skip_collectl=false
    local arch
    arch=$(uname -m)
    if [[ "$arch" == "aarch64" ]] || [[ "$arch" == "arm64" ]]; then
        log_warn "Collectl skipped on ARM64 (compatibility issues on Raspberry Pi)"
        skip_collectl=true
    fi

    if [[ "$skip_collectl" == "true" ]]; then
        install_packages_robust \
            "sysstat:System statistics" \
            "iotop:I/O monitor" \
            "iftop:Network monitor" \
            "nethogs:Network monitor" \
            "bmon:Bandwidth monitor" \
            "nmon:System monitor" \
            "glances:System monitor" \
            "htop:Process monitor" \
            "btop:Resource monitor" \
            "bashtop:Resource monitor" \
            "ncdu:Disk usage" \
            "duf:Disk usage" \
            "pydf:Disk usage" \
            "lsof:List open files" \
            "fuser:Find processes using files" \
            "strace:System call tracer" \
            "ltrace:Library call tracer" \
            "gdb:Debugger" \
            "valgrind:Memory debugger" \
            "perf:Performance analyzer" \
            "flamegraph:Flame graph generator" \
            "sysstat:Performance monitoring" \
            "atop:Advanced system monitor" \
            "sar:System activity reporter" \
            "sadf:SAR data exporter" \
            "dstat:Versatile resource stats" \
            "want:Network analysis tool" \
            "iptraf-ng:Network monitoring" \
            "ngrep:Network grep" \
            "dsniff:Network sniffing" \
            "ettercap:Network monitoring" \
            "bettercap:Network monitoring"
    else
        install_packages_robust \
            "sysstat:System statistics" \
            "iotop:I/O monitor" \
            "iftop:Network monitor" \
            "nethogs:Network monitor" \
            "bmon:Bandwidth monitor" \
            "nmon:System monitor" \
            "glances:System monitor" \
            "htop:Process monitor" \
            "btop:Resource monitor" \
            "bashtop:Resource monitor" \
            "ncdu:Disk usage" \
            "duf:Disk usage" \
            "pydf:Disk usage" \
            "lsof:List open files" \
            "fuser:Find processes using files" \
            "strace:System call tracer" \
            "ltrace:Library call tracer" \
            "gdb:Debugger" \
            "valgrind:Memory debugger" \
            "perf:Performance analyzer" \
            "flamegraph:Flame graph generator" \
            "sysstat:Performance monitoring" \
            "atop:Advanced system monitor" \
            "sar:System activity reporter" \
            "sadf:SAR data exporter" \
            "collectl:Performance data" \
            "dstat:Versatile resource stats" \
            "want:Network analysis tool" \
            "iptraf-ng:Network monitoring" \
            "ngrep:Network grep" \
            "dsniff:Network sniffing" \
            "ettercap:Network monitoring" \
            "bettercap:Network monitoring"
    fi
}

###############################################################################
# Network tunneling tools
###############################################################################
install_network_tunnel_tools() {
    log_info "Installing network tunneling tools..."

    install_ngrok
    install_fastfetch
}

install_ngrok() {
    log_info "Installing ngrok..."

    local arch
    arch=$(detect_architecture)

    if command -v ngrok &>/dev/null; then
        log_success "ngrok already installed"
        return 0
    fi

    local ngrok_url=""
    case "$arch" in
        x86_64) ngrok_url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz" ;;
        arm64)   ngrok_url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz" ;;
        armhf)   ngrok_url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm.tgz" ;;
        *)       log_warn "ngrok: unsupported architecture $arch"; return 0 ;;
    esac

    local temp_file="/tmp/ngrok.tgz"

    echo -n "Downloading ngrok... "
    if curl -fsSL -o "$temp_file" "$ngrok_url" 2>>"${INSTALL_LOG}"; then
        echo "OK"
        echo -n "Installing ngrok... "
        if tar -xzf "$temp_file" -C /usr/local/bin/ 2>>"${INSTALL_LOG}"; then
            rm -f "$temp_file"
            echo "OK"
            log_success "ngrok installed successfully"
            return 0
        else
            echo "FAILED"
            log_error "ngrok: extraction failed"
            rm -f "$temp_file"
            FAILED_PACKAGES+=("ngrok:failed")
            return 0
        fi
    else
        echo "FAILED"
        log_error "ngrok: download failed"
        rm -f "$temp_file"
        FAILED_PACKAGES+=("ngrok:failed")
        return 0
    fi
}

install_fastfetch() {
    log_info "Installing fastfetch..."

    local arch
    arch=$(detect_architecture)

    if command -v fastfetch &>/dev/null; then
        log_success "fastfetch already installed"
        return 0
    fi

    local fastfetch_url=""
    local fastfetch_file=""
    case "$arch" in
        x86_64) 
            fastfetch_url="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb"
            fastfetch_file="fastfetch.deb"
            ;;
        arm64)   
            fastfetch_url="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-aarch64.deb"
            fastfetch_file="fastfetch.deb"
            ;;
        *)       
            log_warn "fastfetch: unsupported architecture $arch"; 
            return 0 
            ;;
    esac

    local temp_file="/tmp/${fastfetch_file}"

    echo -n "Downloading fastfetch... "
    if curl -fsSL -o "$temp_file" "$fastfetch_url" 2>>"${INSTALL_LOG}"; then
        echo "OK"
        echo -n "Installing fastfetch... "
        if dpkg -i "$temp_file" >>"${INSTALL_LOG}" 2>&1; then
            rm -f "$temp_file"
            apt-get install -f -y >>"${INSTALL_LOG}" 2>&1
            echo "OK"
            log_success "fastfetch installed successfully"
            return 0
        else
            echo "FAILED"
            log_error "fastfetch: installation failed"
            rm -f "$temp_file"
            FAILED_PACKAGES+=("fastfetch:failed")
            return 0
        fi
    else
        echo "FAILED"
        log_error "fastfetch: download failed"
        rm -f "$temp_file"
        FAILED_PACKAGES+=("fastfetch:failed")
        return 0
    fi
}

###############################################################################
# Document & media processing
###############################################################################
install_document_tools() {
    log_info "Installing document and media processing tools..."

    install_packages_robust \
        "poppler-utils:PDF utilities" \
        "pandoc:Document converter" \
        "libreoffice:Office suite" \
        "unoconv:Document converter" \
        "pdftk:PDF toolkit" \
        "qpdf:PDF processor" \
        "imagemagick:Image processing" \
        "graphicsmagick:Image processing" \
        "ghostscript:PostScript interpreter" \
        "exiftool:Metadata editor" \
        "ffmpeg:Video processing" \
        "avconv:Video processing" \
        "vlc:VLC player" \
        "mplayer:Media player" \
        "sox:Audio processing" \
        "lame:MP3 encoder" \
        "flac:FLAC audio" \
        "opus-tools:Opus audio" \
        "vorbis-tools:Ogg Vorbis" \
        "mediainfo:Media information" \
        "ffprobe:Media probe"
}

###############################################################################
# Print summary
###############################################################################
print_summary() {
    echo ""
    echo "=============================================================================="
    log_info "Installation Complete"
    echo "=============================================================================="

    local failed_count=${#FAILED_PACKAGES[@]}
    if [[ $failed_count -eq 0 ]]; then
        log_success "All packages installed successfully"
    else
        log_warn "${failed_count} package(s) could not be installed"
        echo ""
        echo "Failed packages:"
        for pkg in "${FAILED_PACKAGES[@]}"; do
            echo "  - ${pkg}"
        done
    fi

    echo ""
    echo "Installation log: ${INSTALL_LOG}"
    echo ""
    echo "Next steps:"
    echo "  - Review failed packages above"
    echo "  - Some tools may require additional configuration"
    echo "  - Check tool documentation for setup instructions"
}

###############################################################################
# Main execution
###############################################################################
main() {
    echo "=============================================================================="
    echo "Linux Server Installation Script"
    echo "Version: ${SCRIPT_VERSION}"
    echo "Architecture: $(detect_architecture)"
    echo "=============================================================================="
    echo ""

    update_system

    echo ""
    echo "=============================================================================="
    echo "Installing packages..."
    echo "=============================================================================="
    echo ""

    install_core_utilities
    install_dev_tools
    install_seo_tools
    install_security_tools
    install_web_tools
    install_monitoring_tools
    install_network_tunnel_tools
    install_document_tools

    print_summary
}

main "$@"
