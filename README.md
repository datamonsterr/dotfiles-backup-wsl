# Dotfiles for Arch Linux WSL

Automated dotfiles management for Arch Linux WSL environment, migrated from Ubuntu WSL.

**Features:**
- ✅ Automated package installation (pacman, AUR, npm)
- ✅ Symlink-based configuration management
- ✅ MCP (Model Context Protocol) servers for Copilot CLI
- ✅ Security-hardened SSH configuration
- ✅ Complete setup and troubleshooting guides
- ✅ Pre-configured for Go, Rust, Node.js, Python development

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/datamonsterr/dotfiles-backup-wsl.git ~/dotfiles
cd ~/dotfiles
```

### 2. Install Packages
```bash
# Install all packages (pacman + AUR + npm)
sudo bash scripts/install-packages.sh all

# Or step-by-step:
sudo bash scripts/install-packages.sh pacman  # Official packages
bash scripts/install-packages.sh yay          # AUR packages
bash scripts/install-packages.sh npm          # Global npm packages
```

### 3. Link Dotfiles
```bash
bash scripts/link-dotfiles.sh
```

This creates symlinks for:
- `~/.zshrc` and `~/.bashrc` (shell configs)
- `~/.gitconfig` (git configuration)
- `~/.ssh/config` (SSH configuration)
- `~/.aws/config` (AWS configuration)

### 4. Setup Copilot CLI & MCP Servers
```bash
bash scripts/setup-mcp-servers.sh
```

### 5. Verify Installation
```bash
# Check shell
exec zsh  # or: exec bash

# Test git
git config user.name

# Test SSH
ssh -T git@github.com

# Test AWS
aws sts get-caller-identity

# Test Copilot
copilot --version
```

## Documentation

📖 **[Complete Setup Guide](./docs/SETUP_GUIDE.md)** - Step-by-step instructions for every aspect of setup

📋 **[Architecture Documentation](./docs/ARCHITECTURE.md)** - Repository structure and component descriptions

🔧 **[Troubleshooting Guide](./docs/TROUBLESHOOTING.md)** - Solutions to common issues

🤖 **[MCP Servers Configuration](./docs/MCP_SERVERS.md)** - Model Context Protocol setup for Copilot CLI

## Repository Structure

```
dotfiles-backup-wsl/
├── docs/                              # Documentation
│   ├── SETUP_GUIDE.md                 # Complete setup instructions
│   ├── ARCHITECTURE.md                # System architecture
│   ├── TROUBLESHOOTING.md             # Common issues & solutions
│   └── MCP_SERVERS.md                 # MCP configuration
├── scripts/                           # Automation scripts
│   ├── install-packages.sh            # Install packages
│   ├── link-dotfiles.sh               # Link configurations
│   ├── setup-mcp-servers.sh           # Setup MCP servers
│   └── mcp-bash-server.sh             # MCP bash wrapper
├── packages/                          # Package lists
│   ├── arch-packages-pacman.txt       # Official Arch packages (~70)
│   ├── arch-packages-yay.txt          # AUR packages (~10)
│   └── npm-global.txt                 # Global npm packages (~15)
├── .zshrc                             # Zsh configuration
├── .bashrc                            # Bash configuration
├── .gitconfig                         # Git configuration
├── .ssh/                              # SSH configuration
│   ├── config                         # SSH client config
│   └── known_hosts                    # Known SSH hosts
├── .aws/                              # AWS configuration
│   └── config                         # AWS CLI config
├── README.md                          # This file
└── apt_packages.txt                   # Original Ubuntu package list (reference)
```

## What's Included

### Packages

**Official Arch Packages (~70):**
- Development tools: gcc, clang, llvm, gdb, cmake, make
- Languages: python3, ruby, perl, node.js, golang, rust
- Tools: git, curl, wget, tmux, vim, docker
- Utilities: htop, jq, ripgrep, fd, exa, bat
- More: build-essential, base-devel, openssh, aws-cli

**AUR Packages (~10):**
- GitHub CLI
- AWS CDK tools
- Copilot CLI
- Mermaid CLI
- Additional development tools

**npm Global (~15):**
- @github/copilot (GitHub Copilot CLI)
- AWS CDK and related tools
- TypeScript, prettier, eslint
- Language servers

### Configurations

**Shell (.zshrc, .bashrc):**
- Go, Rust, Node.js, Python path setup
- Package manager aliases (pacman, yay)
- NVM (Node Version Manager) integration
- Utility functions (mkcd, extract)
- SSH agent auto-start

**Git (.gitconfig):**
- User configuration template
- Default branch settings
- Editor and merge tool configuration

**SSH (.ssh/config):**
- GitHub SSH over port 443
- Modern cipher suites (ChaCha20-Poly1305)
- Ed25519 key support
- Connection pooling and keep-alive
- Security hardening

**AWS (.aws/config):**
- Named profiles support
- Region and output format configuration
- Credential provider chain

## Requirements

- **OS:** Arch Linux WSL (or any Arch Linux system)
- **Shell:** Zsh or Bash (both configured)
- **Git:** For cloning and version control
- **Sudo:** For package installation

## Installation Options

### Automated Installation
```bash
cd ~/dotfiles
sudo bash scripts/install-packages.sh all
bash scripts/link-dotfiles.sh
bash scripts/setup-mcp-servers.sh
```

### Manual Installation
```bash
# 1. Install packages manually
sudo pacman -S --needed $(cat arch-packages-pacman.txt | grep -v '^#' | xargs)
yay -S --needed $(cat arch-packages-yay.txt | grep -v '^#' | xargs)
npm install -g $(cat npm-global.txt | grep -v '^#' | xargs)

# 2. Create symlinks manually
ln -s ~/dotfiles/.zshrc ~/.zshrc
ln -s ~/dotfiles/.bashrc ~/.bashrc
ln -s ~/dotfiles/.gitconfig ~/.gitconfig
mkdir -p ~/.ssh && ln -s ~/dotfiles/.ssh/config ~/.ssh/config
mkdir -p ~/.aws && ln -s ~/dotfiles/.aws/config ~/.aws/config

# 3. Setup SSH keys manually
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
chmod 600 ~/.ssh/config

# 4. Configure AWS manually
aws configure
```

## Configuration

### Customize Package Lists
Edit `arch-packages-pacman.txt`, `arch-packages-yay.txt`, or `npm-global.txt` to add/remove packages:
```bash
nano arch-packages-pacman.txt
bash scripts/install-packages.sh pacman
```

### Customize Shell Configuration
Edit `.zshrc` or `.bashrc` and re-link:
```bash
nano .zshrc
bash scripts/link-dotfiles.sh
```

### Add SSH Hosts
Edit `.ssh/config` to add new host entries:
```bash
cat >> .ssh/config << 'EOF'
Host myserver
  HostName example.com
  User username
  IdentityFile ~/.ssh/id_ed25519
EOF
```

## Security Notes

1. **SSH Keys:** Private keys must be 600 permissions (owner read/write only)
2. **AWS Credentials:** Never commit to git; create `~/.aws/credentials` manually
3. **Secrets:** All sensitive data should be in `~/.aws/credentials`, not in repo
4. **Git:** Use SSH keys for authentication instead of HTTPS with tokens

## Troubleshooting

See [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) for detailed solutions to common issues.

**Quick fixes:**
```bash
# Shell config not loading
source ~/.zshrc

# Symlink broken
bash scripts/link-dotfiles.sh

# Package installation fails
sudo pacman -Syu
sudo bash scripts/install-packages.sh pacman

# SSH authentication fails
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
ssh-add ~/.ssh/id_ed25519
```

## Maintenance

### Update System
```bash
# Update Arch packages
sudo pacman -Syu

# Update npm packages
npm update -g

# Update AUR packages
yay -Syu
```

### Sync Repository
```bash
cd ~/dotfiles
git pull origin main
bash scripts/link-dotfiles.sh  # Re-link if configs changed
```

### Backup Your Setup
```bash
# Backup configs
tar czf dotfiles-backup-$(date +%Y%m%d).tar.gz \
  ~/.zshrc ~/.bashrc ~/.gitconfig ~/.ssh/config ~/.aws/

# Or use rsync to cloud storage
rsync -av ~/.config ~/cloud-backup/
```

## Advanced Usage

### Oh-My-Zsh Integration
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# Then re-run: bash scripts/link-dotfiles.sh
```

### Docker Integration
```bash
# Allow docker without sudo (optional)
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

### WSL-Specific Configuration
```bash
# Use Windows interop from WSL
wslview /path/to/file  # Open in Windows default app

# Mount Windows drives with better permissions
sudo mount -t drvfs C: /mnt/c -o metadata
```

## Contributing

To update or improve these dotfiles:

1. Make changes to configuration files
2. Test thoroughly on Arch Linux WSL
3. Update scripts if needed
4. Update documentation
5. Commit with descriptive message

## Resources

- **Arch Linux Wiki:** https://wiki.archlinux.org/
- **GitHub Copilot CLI:** https://github.com/github/copilot-cli
- **AWS CLI Documentation:** https://docs.aws.amazon.com/cli/
- **WSL Documentation:** https://docs.microsoft.com/en-us/windows/wsl/

## Related Files

- Original Ubuntu package list: `apt_packages.txt`
- Original npm package list: `npm_packages.txt`
- SSH security information: `.ssh/config`
- Git configuration: `.gitconfig`

## License

These dotfiles are provided as-is for personal development use.

---

**Last Updated:** 2026-03-16  
**Tested On:** Arch Linux WSL2, Windows 11

For issues, questions, or improvements: See [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) or create an issue.

