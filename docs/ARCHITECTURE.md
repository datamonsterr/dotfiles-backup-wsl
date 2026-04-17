# Architecture & Directory Structure

This document explains the structure of the dotfiles repository and how each component works together.

## Repository Layout

```
dotfiles-backup-wsl/
├── docs/                          # Documentation
│   ├── SETUP_GUIDE.md             # Complete setup instructions
│   ├── ARCHITECTURE.md            # This file
│   ├── TROUBLESHOOTING.md         # Common issues & solutions
│   └── MCP_SERVERS.md             # MCP configuration details
├── scripts/                       # Automation scripts
│   ├── install-packages.sh        # Install all packages (pacman, yay, npm)
│   ├── link-dotfiles.sh           # Symlink configs to home directory
│   ├── setup-mcp-servers.sh       # Setup MCP servers for Copilot CLI
│   └── mcp-bash-server.sh         # MCP bash server wrapper
├── configs/                       # Configuration templates (for future use)
├── packages/                      # Package lists directory
│   ├── arch-packages-pacman.txt   # Official Arch packages
│   ├── arch-packages-yay.txt      # AUR packages (yay)
│   └── npm-global.txt             # Global npm packages
├── .zshrc                         # Zsh configuration (symlinked to ~/.zshrc)
├── .bashrc                        # Bash configuration (symlinked to ~/.bashrc)
├── .gitconfig                     # Git configuration (symlinked to ~/.gitconfig)
├── .ssh/                          # SSH configuration
│   ├── config                     # SSH client config
│   └── known_hosts                # SSH known hosts (symlinked)
├── .aws/                          # AWS configuration
│   └── config                     # AWS CLI config (symlinked)
├── apt_packages.txt               # Original Ubuntu package list (reference)
├── npm_packages.txt               # Original npm list (reference)
├── README.md                      # Repository overview
└── .git/                          # Git repository metadata
```

## Component Descriptions

### 1. Shell Configurations (.zshrc, .bashrc)

**Purpose:** Set up shell environment, aliases, and functions

**Arch-specific additions:**
- Go path setup (`$GOPATH`, `$GOBIN`)
- Rust/Cargo path setup (`$CARGO_HOME`)
- NVM (Node Version Manager) configuration
- Pacman/yay aliases for package management
- Utility functions (mkcd, extract)

**Location:** Home directory (`~/.zshrc`, `~/.bashrc`)

### 2. Git Configuration (.gitconfig)

**Purpose:** Git user settings and preferences

**Key settings:**
- User name and email
- Default branch (main)
- Colors and aliases
- Editor for commits
- SSH signing (if configured)

**Location:** Home directory (`~/.gitconfig`)

### 3. SSH Configuration (.ssh/config, .ssh/known_hosts)

**Purpose:** SSH client settings and host configuration

**Features:**
- GitHub SSH configuration (port 443)
- Modern cipher suites and algorithms
- SSH key management
- Connection pooling (ControlMaster)
- Host aliases for frequent connections

**Security enhancements:**
- StrictHostKeyChecking with accept-new
- Ed25519 key support
- ChaCha20-Poly1305 ciphers
- ECDSA support with modern curves

**Location:** `~/.ssh/config` (600 permissions), `~/.ssh/known_hosts` (644 permissions)

### 4. AWS Configuration (.aws/config)

**Purpose:** AWS CLI and SDK configuration

**Settings:**
- Default AWS region
- Output format (json, table, text)
- Named profiles for multiple accounts
- Credential provider chain

**Location:** `~/.aws/config` (600 permissions)

**Note:** AWS credentials are NOT stored in the repo for security. Create `.aws/credentials` manually.

### 5. Package Lists

#### arch-packages-pacman.txt
Official Arch Linux packages (~70 items)
- Development tools (gcc, clang, llvm, gdb)
- Languages (python, ruby, perl, node.js)
- System utilities (tmux, htop, jq, fd, ripgrep)
- Networking (curl, wget, openssh)
- Docker and containers

#### arch-packages-yay.txt
AUR packages via yay (~10 items)
- GitHub CLI
- AWS CDK tools
- Copilot CLI
- Mermaid CLI
- Additional tools

#### npm-global.txt
Global npm packages (~15 items)
- @github/copilot (GitHub Copilot CLI)
- AWS CDK
- prettier, eslint, typescript
- Language servers

### 6. Installation Scripts

#### install-packages.sh
Automated package installation for Arch Linux

**Features:**
- Validates Arch Linux environment
- Installs from pacman (official repos)
- Auto-installs and configures yay for AUR
- Installs global npm packages
- Colored output and error handling
- Support for individual or all-in-one installation

**Usage:**
```bash
./scripts/install-packages.sh [pacman|yay|npm|all]
```

#### link-dotfiles.sh
Symlinks configuration files to home directory

**Features:**
- Automatic backup of existing files
- Safe symlink creation
- Directory creation as needed
- Permission handling (SSH/AWS configs)
- Symlink verification

**Usage:**
```bash
./scripts/link-dotfiles.sh
```

#### setup-mcp-servers.sh
Configures Model Context Protocol servers for Copilot CLI

**Creates:**
- MCP servers configuration (`~/.copilot/mcp_servers.json`)
- Copilot CLI config (`~/.copilot/config.json`)
- MCP server wrappers

**Installs:**
- @modelcontextprotocol/server-filesystem
- @modelcontextprotocol/server-git
- @modelcontextprotocol/server-bash
- @modelcontextprotocol/server-stdio

**Usage:**
```bash
./scripts/setup-mcp-servers.sh
```

## Configuration Flow

```
User runs setup scripts
        ↓
1. install-packages.sh
   - Install base system packages
   - Install development tools
   - Install runtime environments
        ↓
2. link-dotfiles.sh
   - Symlink shell configs
   - Symlink git config
   - Symlink SSH/AWS configs
        ↓
3. setup-mcp-servers.sh
   - Install MCP packages
   - Create Copilot config
   - Setup language servers
        ↓
Development environment ready
(Shell reloads config automatically)
```

## Path Management

### Important Directories

```
~/.local/bin          # User-installed executables
~/.config/            # Application configs
~/.ssh/               # SSH keys and config
~/.aws/               # AWS credentials and config
~/.zsh_history        # Zsh history file
~/go/bin              # Go binaries
~/.cargo/bin          # Rust binaries
~/.nvm/               # Node version manager
```

### PATH Configuration

The shells set PATH in this order (highest priority first):
1. `~/.local/bin` - User scripts
2. `~/bin` - Additional user binaries
3. `/usr/local/bin` - Local system binaries
4. `$GOBIN` (~go/bin) - Go binaries
5. `${CARGO_HOME}/bin` (~.cargo/bin) - Rust binaries
6. `/usr/bin` - System binaries

## Package Management Strategy

### Arch Linux (pacman)
- Official, stable packages
- Faster updates and security patches
- Good binary cache
- Used for most tools

### AUR (yay)
- Community-maintained packages
- Cutting-edge versions
- For tools not in official repos
- Requires yay setup

### npm (global)
- Node.js tool ecosystem
- Language servers
- CLI tools
- Tools not in pacman/AUR

## Security Considerations

1. **SSH Keys:**
   - Private keys: 600 permissions (owner read/write only)
   - Public keys: 644 permissions
   - Never commit to git
   - Keep backup in secure location

2. **AWS Credentials:**
   - Not stored in repo
   - Create `~/.aws/credentials` manually
   - Use IAM roles when possible
   - Enable MFA for root account

3. **Git Configuration:**
   - Use SSH keys instead of HTTPS
   - Enable commit signing if available
   - Keep .gitconfig in repo (safe, no secrets)

4. **Shell History:**
   - Keep history disabled for sensitive commands
   - Consider encrypting history file
   - Review before sharing shell scripts

## Arch-specific Adaptations

### From Ubuntu to Arch

| Ubuntu | Arch | Note |
|--------|------|------|
| apt/apt-get | pacman | Official package manager |
| ppa-manager | yay | AUR helper |
| /etc/apt/sources.list | /etc/pacman.conf | Package configuration |
| apt update | pacman -Sy | Sync package DB |
| apt install | pacman -S | Install package |
| apt upgrade | pacman -Syu | Full system upgrade |
| systemd | systemd | Same init system |
| /usr/bin | /usr/bin | Same binary location |
| /home/user | /home/user | Same home location |

### WSL-specific Notes

1. Systemd is available in modern WSL but may not fully work
2. Some system services won't run (no real kernel)
3. File permissions may be different on /mnt/c/
4. Use `/mnt/c/Users/...` to access Windows files
5. Performance is good for development, not for I/O-heavy workloads

## Customization Points

To customize this setup for your needs:

1. **Edit package lists:** Add/remove packages in `arch-packages-*.txt`
2. **Modify shell configs:** Edit `.zshrc` or `.bashrc` and re-link
3. **Add SSH hosts:** Edit `.ssh/config` with new host entries
4. **Create aliases:** Add to shell configs or create `~/.bash_aliases`
5. **Configure git:** Edit `.gitconfig` with personal settings

## Updating the Repository

```bash
cd ~/dotfiles

# Pull latest changes
git pull origin main

# Reinstall packages (if lists updated)
bash scripts/install-packages.sh all

# Re-link dotfiles (if configs updated)
bash scripts/link-dotfiles.sh

# Update MCP servers (if config changed)
bash scripts/setup-mcp-servers.sh
```

## Troubleshooting by Component

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for detailed troubleshooting guides.

Quick reference:
- **Shell issues:** Source the config file or restart terminal
- **Git issues:** Check `.gitconfig` and SSH keys
- **SSH issues:** Verify key permissions (600) and key types
- **Package issues:** Update pacman, check for conflicts
- **MCP issues:** Reinstall npm packages, check config JSON

---

**Related Documentation:**
- [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Complete setup instructions
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues and solutions
- [MCP_SERVERS.md](./MCP_SERVERS.md) - MCP server configuration
