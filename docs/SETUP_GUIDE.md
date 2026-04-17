# Arch Linux WSL Dotfiles Setup Guide

Complete step-by-step guide for restoring your development environment from this dotfiles repository to Arch Linux WSL.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Install Packages](#install-packages)
4. [Link Dotfiles](#link-dotfiles)
5. [Configure SSH](#configure-ssh)
6. [Configure AWS](#configure-aws)
7. [Setup Copilot CLI & MCP Servers](#setup-copilot-cli--mcp-servers)
8. [Verification & Troubleshooting](#verification--troubleshooting)

---

## Prerequisites

### System Requirements
- Arch Linux WSL (Windows Subsystem for Linux)
- `git` installed
- `sudo` access for package installation

### Before You Start
1. Clone this repository to your home directory:
   ```bash
   cd ~
   git clone https://github.com/datamonsterr/dotfiles-backup-wsl.git ~/dotfiles
   cd ~/dotfiles
   ```

2. Ensure you have the following files in the repo:
   - `.zshrc` and `.bashrc` (shell configs)
   - `.gitconfig` (git configuration)
   - `.ssh/config` (SSH configuration)
   - `.aws/config` (AWS credentials - if needed)
   - `scripts/` directory with shell scripts
   - `arch-packages-pacman.txt` and `arch-packages-yay.txt`

---

## Initial Setup

### Step 1: Update System
```bash
sudo pacman -Syu
sudo pacman -S base-devel git
```

### Step 2: Install Required Tools
```bash
sudo pacman -S zsh tmux vim curl wget
```

### Step 3: Create Essential Directories
```bash
mkdir -p ~/.ssh
mkdir -p ~/.aws
mkdir -p ~/.local/bin
mkdir -p ~/go/bin
mkdir -p ~/.cargo/bin
chmod 700 ~/.ssh
chmod 700 ~/.aws
```

---

## Install Packages

### Option A: Quick Install (Recommended)
```bash
cd ~/dotfiles
# Install all packages (pacman, yay AUR, npm)
sudo bash scripts/install-packages.sh all
```

### Option B: Step-by-Step Installation

#### 1. Install pacman packages
```bash
cd ~/dotfiles
sudo bash scripts/install-packages.sh pacman
```

This installs ~70 essential packages including:
- Development tools (gcc, clang, llvm, gdb)
- Python, Ruby, Perl, Node.js
- Docker, AWS CLI
- System utilities (htop, jq, ripgrep, fd, etc.)

#### 2. Install AUR packages (requires yay)
```bash
cd ~/dotfiles
bash scripts/install-packages.sh yay
```

The script will:
- Auto-install `yay` if not present
- Install AUR packages (aws-cdk, copilot-cli, etc.)

#### 3. Install npm global packages
```bash
cd ~/dotfiles
bash scripts/install-packages.sh npm
```

Installs:
- `@github/copilot` - GitHub Copilot CLI
- AWS CDK tools
- Mermaid CLI, prettier, eslint, typescript

### Manual Package Installation

If scripts fail, install manually:

**Pacman packages:**
```bash
sudo pacman -S --needed $(cat arch-packages-pacman.txt | grep -v '^#' | xargs)
```

**AUR packages (with yay):**
```bash
yay -S $(cat arch-packages-yay.txt | grep -v '^#' | xargs)
```

**npm packages:**
```bash
npm install -g $(cat npm-global.txt | grep -v '^#' | xargs)
```

---

## Link Dotfiles

The `link-dotfiles.sh` script symlinks all config files from the repo to your home directory with automatic backups.

```bash
cd ~/dotfiles
bash scripts/link-dotfiles.sh
```

**What it does:**
- Backs up existing files (appends `.backup.<timestamp>`)
- Creates symlinks for:
  - `~/.zshrc` → `.zshrc`
  - `~/.bashrc` → `.bashrc`
  - `~/.gitconfig` → `.gitconfig`
  - `~/.ssh/config` → `.ssh/config`
  - `~/.ssh/known_hosts` → `.ssh/known_hosts` (if exists)
  - `~/.aws/config` → `.aws/config` (if exists)

**Verify symlinks:**
```bash
ls -la ~/ | grep "^l"  # List all symlinks
cat ~/.zshrc           # Should show repo content
```

---

## Configure SSH

### 1. Review SSH Config
The repo includes an optimized SSH config with security hardening:

```bash
cat ~/.ssh/config
```

**Current configuration includes:**
- GitHub SSH over port 443 (works through most firewalls)
- Ed25519 key support (modern, secure)
- Connection pooling and keep-alive settings
- Modern cipher suites

### 2. Generate or Import SSH Keys

#### If you're new to SSH:
```bash
# Generate new Ed25519 key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "your.email@example.com"

# Generate RSA key (backup/older systems)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -C "your.email@example.com"
```

#### If migrating existing keys:
```bash
# Copy private keys from backup
# Adjust permissions
chmod 600 ~/.ssh/id_ed25519*
chmod 600 ~/.ssh/id_rsa*
chmod 644 ~/.ssh/known_hosts
```

### 3. Add Keys to SSH Agent
```bash
# Start SSH agent
eval "$(ssh-agent -s)"

# Add keys
ssh-add ~/.ssh/id_ed25519
ssh-add ~/.ssh/id_rsa  # if using RSA

# List loaded keys
ssh-add -l
```

### 4. Test SSH Connection
```bash
# GitHub
ssh -T git@github.com

# Should output: Hi username! You've successfully authenticated...

# Using alternate config
ssh -T github-nuoa
```

### 5. Permanent SSH Agent Setup
Add to `.zshrc` or `.bashrc`:
```bash
# Auto-start ssh-agent and load keys
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
```

---

## Configure AWS

### 1. Set Up AWS Credentials

#### Option A: Interactive Setup
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Default region, Default output format
```

#### Option B: Manual File Creation
```bash
# Create credentials file
mkdir -p ~/.aws
cat > ~/.aws/credentials << 'EOF'
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY

[profile-name]
aws_access_key_id = KEY_2
aws_secret_access_key = SECRET_2
EOF

chmod 600 ~/.aws/credentials

# Create config file
cat > ~/.aws/config << 'EOF'
[default]
region = us-east-1
output = json

[profile profile-name]
region = eu-west-1
output = json
EOF

chmod 600 ~/.aws/config
```

### 2. Test AWS CLI
```bash
aws sts get-caller-identity
# Should display your AWS account information
```

### 3. AWS CDK Setup
```bash
# Install AWS CDK (already in npm packages)
npm install -g aws-cdk

# Verify installation
cdk --version

# Configure CDK (optional)
cdk init --list-templates
```

---

## Setup Copilot CLI & MCP Servers

### 1. Install Copilot CLI
Already installed via npm packages. Verify:
```bash
copilot --version
```

### 2. Setup MCP (Model Context Protocol) Servers
```bash
cd ~/dotfiles
bash scripts/setup-mcp-servers.sh
```

**What it does:**
- Creates `~/.copilot/mcp_servers.json`
- Creates `~/.copilot/config.json`
- Installs MCP npm packages:
  - `@modelcontextprotocol/server-filesystem`
  - `@modelcontextprotocol/server-git`
  - `@modelcontextprotocol/server-bash`
  - `@modelcontextprotocol/server-stdio`

### 3. Verify Copilot CLI Config
```bash
# Check config file
cat ~/.copilot/config.json

# Check MCP servers config
cat ~/.copilot/mcp_servers.json
```

### 4. Configure Copilot CLI with API Keys
```bash
# Add your API key (if needed)
export COPILOT_API_KEY="your-api-key-here"

# Test Copilot
copilot --help
```

### 5. Setup MCP Server Integration (Optional Advanced)
If using with VS Code or other editors:
```bash
# Install VS Code MCP extension
# Or configure in your editor's settings.json:
# "models.mcp": { "enabled": true, "servers": "~/.copilot/mcp_servers.json" }
```

---

## Verification & Troubleshooting

### Quick Verification Checklist
```bash
# 1. Shell configuration
echo $SHELL              # Should be /bin/zsh or /bin/bash
source ~/.zshrc         # Should load without errors

# 2. Git configuration
git config --list       # Should show your settings
git config user.name    # Should display name

# 3. SSH
ssh -T git@github.com   # Should authenticate

# 4. Development tools
git --version
docker --version
python3 --version
node --version
npm --version
go version
rustc --version         # if installed

# 5. AWS
aws sts get-caller-identity

# 6. Copilot CLI
copilot --version
cat ~/.copilot/config.json

# 7. Package manager (Arch)
pacman -V
yay -V
```

### Common Issues & Solutions

#### Issue: Shell not updating
**Solution:**
```bash
# Reload shell config
source ~/.zshrc
# Or restart terminal
exec zsh
```

#### Issue: SSH key not found
**Solution:**
```bash
# Check if keys exist
ls -la ~/.ssh/
# Generate new key if missing
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
# Add to agent
ssh-add ~/.ssh/id_ed25519
```

#### Issue: Package installation fails
**Solution:**
```bash
# Update package database
sudo pacman -Sy
# Retry installation
sudo pacman -S package-name
# Or for AUR
yay -S aur-package-name
```

#### Issue: Copilot CLI not found
**Solution:**
```bash
# Check npm global packages
npm list -g @github/copilot
# Reinstall if needed
npm install -g @github/copilot@latest
```

#### Issue: MCP servers not working
**Solution:**
```bash
# Reinstall MCP packages
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @modelcontextprotocol/server-git
# Check configuration
cat ~/.copilot/mcp_servers.json
# Verify Node.js
node --version
```

#### Issue: WSL-specific problems
**Solution:**
```bash
# Check if running on WSL
uname -a  # Should show "WSL" or "Microsoft"
# Install WSL utilities
sudo pacman -S wslu
# Update WSL from Windows: wsl --update
```

---

## Advanced Configuration

### Customizing Shell Aliases
Edit `~/.zshrc` or `~/.bashrc` to add custom aliases:
```bash
# Add to ~/.zshrc
alias ll='ls -lah'
alias dev='cd ~/development'
alias dots='cd ~/dotfiles'
```

### Configuring Vim
```bash
# Create your vim config
cat > ~/.vimrc << 'EOF'
set number
set tabstop=2
set shiftwidth=2
set expandtab
EOF
```

### Setting Default Editor
```bash
# Add to ~/.zshrc or ~/.bashrc
export EDITOR=vim
export VISUAL=vim
```

### Installing Oh-My-Zsh (Optional)
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# Then re-run link-dotfiles.sh
```

---

## Maintenance & Updates

### Regular Updates
```bash
# Update Arch packages
sudo pacman -Syu

# Update npm packages
npm update -g

# Update aws-cdk
npm install -g aws-cdk@latest
```

### Backup Dotfiles
```bash
# Make a backup of current dotfiles
tar czf ~/dotfiles-backup-$(date +%Y%m%d).tar.gz ~/.zshrc ~/.bashrc ~/.gitconfig ~/.ssh/config ~/.aws/

# Or sync to cloud storage
rsync -av ~/.config ~/backup/
```

### Sync Repo Updates
```bash
cd ~/dotfiles
git pull origin main
bash scripts/link-dotfiles.sh  # Re-link if configs updated
```

---

## Next Steps

1. **Customize your environment:**
   - Edit `.zshrc` and `.bashrc` to add personal settings
   - Configure your favorite editor (vim, neovim, VS Code)
   - Add personal aliases and functions

2. **Setup development environments:**
   - Configure docker if needed: `sudo groupadd docker && sudo usermod -aG docker $USER`
   - Setup NVM for multiple Node versions
   - Configure Python virtual environments

3. **Explore Arch tools:**
   - `paru` or `yay` for AUR packages
   - `systemctl` for service management (limited on WSL)
   - `pacman-contrib` for useful utilities

4. **Integrate with Windows:**
   - Use `wslview` to open Windows apps from WSL
   - Setup VS Code Remote WSL
   - Configure Windows Terminal for better UX

---

## Support & Resources

- **Arch Linux Wiki:** https://wiki.archlinux.org/
- **GitHub Copilot CLI:** https://github.com/github/copilot-cli
- **AWS CLI Documentation:** https://docs.aws.amazon.com/cli/
- **WSL Documentation:** https://docs.microsoft.com/en-us/windows/wsl/

---

**Last Updated:** 2026-03-16  
**For issues or questions:** Check the troubleshooting section or create an issue in the repository.
