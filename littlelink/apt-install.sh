#!/usr/bin/env bash
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"
FAILED_PKGS="${LOG_DIR}/failed_packages.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "[${GREEN}INFO${NC}] $*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" >> "$LOG_FILE"
}

log_warn() {
    echo -e "[${YELLOW}WARN${NC}] $*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $*" >> "$LOG_FILE"
}

log_error() {
    echo -e "[${RED}ERROR${NC}] $*" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >> "$LOG_FILE"
}

log_section() {
    echo ""
    echo "========================================"
    echo "  $*"
    echo "========================================"
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] === $* ===" >> "$LOG_FILE"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_warn "This script requires root privileges. Use sudo."
        log_info "Re-running with sudo..."
        exec sudo "$0" "$@"
    fi
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO_ID="${ID}"
        DISTRO_VERSION="${VERSION_ID}"
        DISTRO_NAME="${NAME}"
    else
        log_error "Cannot detect distribution"
        exit 1
    fi
    log_info "Detected distribution: ${DISTRO_NAME} (${DISTRO_ID} ${DISTRO_VERSION})"
}

update_packages() {
    log_section "Updating Package Lists"
    if apt-get update -y >> "$LOG_FILE" 2>&1; then
        log_info "Package lists updated successfully"
    else
        log_warn "Failed to update package lists"
    fi
}

install_package() {
    local pkg="$1"
    local description="${2:-}"
    local category="${3:-unknown}"

    log_info "Installing: ${pkg} ${description:+- $description}"

    if apt-get install -y "$pkg" >> "$LOG_FILE" 2>&1; then
        log_info "Successfully installed: ${pkg}"
        return 0
    else
        log_warn "Package not available or failed to install: ${pkg}"
        echo "${pkg}|${category}|${DISTRO_ID}" >> "$FAILED_PKGS"
        return 1
    fi
}

install_packages() {
    local category="$1"
    shift
    local packages=("$@")
    local failed=0

    log_section "Installing ${category}"

    for pkg in "${packages[@]}"; do
        if ! install_package "$pkg" "" "$category"; then
            ((failed++))
        fi
    done

    if [[ $failed -gt 0 ]]; then
        log_warn "${failed} package(s) in '${category}' failed to install"
    else
        log_info "All ${category} packages installed successfully"
    fi
}

install_core_utilities() {
    install_packages "Core System Utilities" \
        ca-certificates \
        curl \
        wget \
        gnupg \
        lsb-release \
        software-properties-common \
        build-essential \
        unzip \
        zip \
        p7zip-full \
        rsync \
        tree \
        htop \
        tmux \
        screen \
        jq \
        yq \
        entr \
        inxi
}

install_devops_tools() {
    install_packages "DevOps & Version Control" \
        git \
        git-lfs \
        make \
        cmake
}

install_container_deps() {
    install_packages "Container Dependencies" \
        uidmap \
        iptables \
        iproute2
}

install_networking_tools() {
    install_packages "Networking & Cybersecurity" \
        nmap \
        tcpdump \
        wireshark-common \
        tshark \
        netcat-openbsd \
        socat \
        openssl \
        pass
}

install_web_tools() {
    install_packages "Web, API & SEO Tooling" \
        httpie \
        ripgrep \
        fd-find
}

install_document_tools() {
    install_packages "Document Conversion & Processing" \
        poppler-utils \
        pandoc \
        libreoffice-common \
        unoconv \
        pdftk
}

install_media_tools() {
    install_packages "Image, Video & OCR" \
        imagemagick \
        ghostscript \
        graphicsmagick \
        exiftool \
        ffmpeg \
        tesseract-ocr \
        ocrmypdf
}

install_python_tools() {
    install_packages "Python Development" \
        python3 \
        python3-venv \
        python3-pip \
        python3-dev
}

install_debug_tools() {
    install_packages "Debugging & Reverse Engineering" \
        strace \
        ltrace \
        gdb \
        binutils \
        radare2
}

install_emulators() {
    install_packages "Retro Emulators" \
        vice \
        hatari \
        minivmac \
        basilisk2
}

install_disk_tools() {
    install_packages "Disk, Filesystem & Forensics" \
        fdisk \
        parted \
        testdisk \
        sleuthkit \
        ntfs-3g \
        exfatprogs
}

install_monitoring_tools() {
    install_packages "Monitoring & Logging" \
        sysstat \
        iotop \
        iftop \
        lsof \
        logrotate
}

install_ssh_tools() {
    install_packages "SSH & Remote Access" \
        openssh-client \
        openssh-server \
        sshpass \
        mosh
}

install_remote_desktop() {
    install_packages "Remote Desktop Services" \
        xrdp \
        remmina \
        tigervnc-viewer \
        realvnc-viewer
}

install_vscode_extensions() {
    log_section "Installing VS Code Extensions"

    if ! command -v code &> /dev/null; then
        log_warn "VS Code not found. Skipping extensions installation."
        return
    fi

    local extensions=(
        "dbaeumer.vscode-eslint"
        "esbenp.prettier-vscode"
        "ms-python.python"
        "stylelint.vscode-stylelint"
        "htmlhint.vscode-htmlhint"
        "meganrogge.template-string-converter"
        "streetsidesoftware.code-spell-checker"
        "mikestead.dotenv"
        "oderwat.indent-rainbow"
        "yzhang.markdown-all-in-one"
        "ms-azuretools.vscode-docker"
        "bradlc.vscode-tailwindcss"
        "formulahendry.auto-rename-tag"
        "ms-vscode.vscode-typescript-next"
        "ms-vscode.live-server"
        "mehendy.vscode-rainbow-csv"
        "GitHub.copilot"
        "opencode.opencode"
        "dracula-theme Official"
        "humao.rest-client"
        "hediet.vscode-drawio"
        "ms-vscode.hexeditor"
        "eg2.vscode-npm-script"
        "eamodio.gitlens"
        "ddev.ddev-vscode"
    )

    for ext in "${extensions[@]}"; do
        log_info "Installing VS Code extension: ${ext}"
        if code --install-extension "$ext" --force >> "$LOG_FILE" 2>&1; then
            log_info "Successfully installed: ${ext}"
        else
            log_warn "Failed to install: ${ext}"
        fi
    done
}

cleanup() {
    log_section "Cleanup"
    apt-get autoremove -y >> "$LOG_FILE" 2>&1
    apt-get autoclean >> "$LOG_FILE" 2>&1
    log_info "Cleanup completed"
}

print_summary() {
    log_section "Installation Summary"

    if [[ -f "$FAILED_PKGS" ]]; then
        local failed_count=$(wc -l < "$FAILED_PKGS")
        log_warn "${failed_count} package(s) failed to install"
        log_info "Failed packages list: ${FAILED_PKGS}"
    else
        log_info "All packages installed successfully"
    fi

    log_info "Full installation log: ${LOG_FILE}"
    log_info "Run 'shellcheck ${0}' to validate this script"
}

main() {
    mkdir -p "$LOG_DIR"

    log_section "Starting Installation"
    log_info "Script: ${0}"
    log_info "Log file: ${LOG_FILE}"

    check_root
    detect_distro
    update_packages

    install_core_utilities
    install_devops_tools
    install_container_deps
    install_networking_tools
    install_web_tools
    install_document_tools
    install_media_tools
    install_python_tools
    install_debug_tools
    install_emulators
    install_disk_tools
    install_monitoring_tools
    install_ssh_tools
    install_remote_desktop

    install_vscode_extensions

    cleanup
    print_summary

    log_section "Installation Complete"
}

main "$@"
