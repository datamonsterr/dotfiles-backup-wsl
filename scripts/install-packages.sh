#!/bin/bash
# Install packages for Arch Linux WSL setup
# Usage: ./install-packages.sh [pacman|yay|npm|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$SCRIPT_DIR"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Check if running on Arch
check_arch() {
  if ! command -v pacman &> /dev/null; then
    log_error "This script requires Arch Linux. pacman not found."
  fi
  log_success "Running on Arch Linux"
}

# Install pacman packages
install_pacman() {
  log_info "Installing pacman packages..."
  
  if [ ! -f "$REPO_ROOT/arch-packages-pacman.txt" ]; then
    log_error "arch-packages-pacman.txt not found"
  fi
  
  local packages=$(grep -v '^#' "$REPO_ROOT/arch-packages-pacman.txt" | grep -v '^$' | tr '\n' ' ')
  
  if [ -z "$packages" ]; then
    log_warn "No packages to install from pacman list"
    return
  fi
  
  log_info "Packages to install: $(echo $packages | wc -w) items"
  echo "$packages" | xargs sudo pacman -S --needed
  log_success "Pacman packages installed"
}

# Install yay and AUR packages
install_yay() {
  log_info "Setting up yay (AUR helper)..."
  
  if ! command -v yay &> /dev/null; then
    log_warn "yay not found, installing..."
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si
    cd -
    log_success "yay installed"
  else
    log_success "yay already installed"
  fi
  
  if [ ! -f "$REPO_ROOT/arch-packages-yay.txt" ]; then
    log_warn "arch-packages-yay.txt not found, skipping AUR packages"
    return
  fi
  
  local packages=$(grep -v '^#' "$REPO_ROOT/arch-packages-yay.txt" | grep -v '^$' | tr '\n' ' ')
  
  if [ -z "$packages" ]; then
    log_warn "No AUR packages to install"
    return
  fi
  
  log_info "AUR packages to install: $(echo $packages | wc -w) items"
  yay -S --needed $packages
  log_success "AUR packages installed"
}

# Install npm global packages
install_npm() {
  log_info "Installing npm global packages..."
  
  if ! command -v npm &> /dev/null; then
    log_warn "npm not found, please install nodejs first: pacman -S nodejs"
    return
  fi
  
  if [ ! -f "$REPO_ROOT/npm-global.txt" ]; then
    log_warn "npm-global.txt not found"
    return
  fi
  
  local packages=$(grep -v '^#' "$REPO_ROOT/npm-global.txt" | grep -v '^$' | tr '\n' ' ')
  
  if [ -z "$packages" ]; then
    log_warn "No npm packages to install"
    return
  fi
  
  log_info "npm packages to install: $(echo $packages | wc -w) items"
  npm install -g $packages
  log_success "npm packages installed"
}

# Main
main() {
  local target="${1:-all}"
  
  check_arch
  
  case "$target" in
    pacman)
      install_pacman
      ;;
    yay)
      install_yay
      ;;
    npm)
      install_npm
      ;;
    all)
      install_pacman
      install_yay
      install_npm
      ;;
    *)
      log_error "Usage: $0 [pacman|yay|npm|all]"
      ;;
  esac
  
  log_success "Installation complete!"
}

main "$@"
