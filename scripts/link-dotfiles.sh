#!/bin/bash
# Link dotfiles from repo to home directory
# Supports both stow-style and direct linking

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$SCRIPT_DIR"
HOME_DIR="$HOME"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Backup existing file before linking
backup_file() {
  local file="$1"
  if [ -e "$file" ]; then
    local backup="${file}.backup.$(date +%s)"
    log_warn "Backing up $file → $backup"
    mv "$file" "$backup"
  fi
}

# Create symlink with safety checks
safe_link() {
  local src="$1"
  local dest="$2"
  
  if [ ! -e "$src" ]; then
    log_warn "Source not found: $src"
    return 1
  fi
  
  # Create destination directory if needed
  local dest_dir=$(dirname "$dest")
  if [ ! -d "$dest_dir" ]; then
    mkdir -p "$dest_dir"
    log_info "Created directory: $dest_dir"
  fi
  
  # Remove old symlink or backup existing file
  if [ -L "$dest" ]; then
    log_info "Removing old symlink: $dest"
    rm "$dest"
  elif [ -e "$dest" ]; then
    backup_file "$dest"
  fi
  
  # Create new symlink
  ln -s "$src" "$dest"
  log_success "Linked: $dest → $src"
}

# Link shell configs
link_shell_configs() {
  log_info "Linking shell configurations..."
  safe_link "$REPO_ROOT/.zshrc" "$HOME_DIR/.zshrc"
  safe_link "$REPO_ROOT/.bashrc" "$HOME_DIR/.bashrc"
  log_success "Shell configs linked"
}

# Link git config
link_git_config() {
  log_info "Linking git configuration..."
  if [ -f "$REPO_ROOT/.gitconfig" ]; then
    safe_link "$REPO_ROOT/.gitconfig" "$HOME_DIR/.gitconfig"
    log_success "Git config linked"
  else
    log_warn "Git config not found in repo"
  fi
}

# Link SSH config
link_ssh_config() {
  log_info "Linking SSH configuration..."
  if [ -d "$REPO_ROOT/.ssh" ]; then
    mkdir -p "$HOME_DIR/.ssh"
    
    # Link config file
    if [ -f "$REPO_ROOT/.ssh/config" ]; then
      safe_link "$REPO_ROOT/.ssh/config" "$HOME_DIR/.ssh/config"
      chmod 600 "$HOME_DIR/.ssh/config"
    fi
    
    # Link known_hosts if it exists
    if [ -f "$REPO_ROOT/.ssh/known_hosts" ]; then
      safe_link "$REPO_ROOT/.ssh/known_hosts" "$HOME_DIR/.ssh/known_hosts"
      chmod 644 "$HOME_DIR/.ssh/known_hosts"
    fi
    
    log_success "SSH config linked"
  else
    log_warn "SSH directory not found in repo"
  fi
}

# Link AWS config
link_aws_config() {
  log_info "Linking AWS configuration..."
  if [ -d "$REPO_ROOT/.aws" ]; then
    mkdir -p "$HOME_DIR/.aws"
    
    if [ -f "$REPO_ROOT/.aws/config" ]; then
      safe_link "$REPO_ROOT/.aws/config" "$HOME_DIR/.aws/config"
      chmod 600 "$HOME_DIR/.aws/config"
    fi
    
    log_success "AWS config linked"
  else
    log_warn "AWS directory not found in repo"
  fi
}

# Create default config files if missing
create_default_configs() {
  log_info "Ensuring default configs exist..."
  
  # SSH directory
  if [ ! -d "$HOME_DIR/.ssh" ]; then
    mkdir -p "$HOME_DIR/.ssh"
    chmod 700 "$HOME_DIR/.ssh"
    log_success "Created ~/.ssh directory"
  fi
  
  # AWS directory
  if [ ! -d "$HOME_DIR/.aws" ]; then
    mkdir -p "$HOME_DIR/.aws"
    chmod 700 "$HOME_DIR/.aws"
    log_success "Created ~/.aws directory"
  fi
  
  # .local/bin for user scripts
  if [ ! -d "$HOME_DIR/.local/bin" ]; then
    mkdir -p "$HOME_DIR/.local/bin"
    chmod 755 "$HOME_DIR/.local/bin"
    log_success "Created ~/.local/bin directory"
  fi
}

# Verify all links
verify_links() {
  log_info "Verifying symlinks..."
  
  local verified=0
  for link in "$HOME_DIR/.zshrc" "$HOME_DIR/.bashrc" "$HOME_DIR/.gitconfig"; do
    if [ -L "$link" ]; then
      log_success "✓ $link"
      ((verified++))
    elif [ -f "$link" ]; then
      log_warn "⚠ $link exists but is not a symlink"
    fi
  done
  
  log_info "Verified $verified symlinks"
}

# Main
main() {
  log_info "Starting dotfile linking process..."
  log_info "Repo root: $REPO_ROOT"
  log_info "Home directory: $HOME_DIR"
  
  create_default_configs
  link_shell_configs
  link_git_config
  link_ssh_config
  link_aws_config
  verify_links
  
  log_success "All dotfiles linked successfully!"
  log_info "Please restart your shell or run: source ~/.zshrc"
}

main "$@"
