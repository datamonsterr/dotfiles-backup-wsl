# Troubleshooting Guide

Solutions to common issues when setting up dotfiles on Arch Linux WSL.

## Quick Diagnosis

Run this to check your system:
```bash
#!/bin/bash
echo "=== System Info ==="
uname -a
echo "=== Shell ==="
echo $SHELL
echo "=== Git ==="
git --version && git config user.name
echo "=== SSH ==="
ssh -T git@github.com 2>&1 | head -1
echo "=== Packages ==="
pacman -V
yay -V 2>/dev/null || echo "yay not installed"
echo "=== Development Tools ==="
python3 --version
node --version
npm --version
docker --version 2>/dev/null || echo "docker not installed"
echo "=== Copilot ==="
copilot --version 2>/dev/null || echo "copilot not installed"
```

---

## Shell & Configuration Issues

### Problem: Shell not sourcing config file

**Symptoms:**
- Aliases not working
- PATH not set correctly
- Prompt looks wrong

**Solutions:**

```bash
# 1. Manually source the file
source ~/.zshrc
# or
source ~/.bashrc

# 2. Check if symlink is correct
ls -la ~/.zshrc
readlink ~/.zshrc  # Should point to ~/dotfiles/.zshrc

# 3. Re-link dotfiles
cd ~/dotfiles
bash scripts/link-dotfiles.sh

# 4. Restart shell
exec zsh
# or
exec bash

# 5. Check for syntax errors
zsh -n ~/.zshrc  # Check syntax without executing
# or
bash -n ~/.bashrc
```

### Problem: Command not found (after installing packages)

**Symptoms:**
- `pacman: command not found` (after installation)
- `npm: command not found` (after npm install)

**Solutions:**

```bash
# 1. Reload shell
source ~/.zshrc

# 2. Update PATH manually
export PATH=$PATH:/usr/bin:/usr/local/bin

# 3. Check if package really installed
pacman -Q package-name
npm list -g package-name

# 4. Reinstall package
sudo pacman -S package-name --force
# or
npm install -g package@latest
```

### Problem: Oh-My-Zsh not found

**Symptoms:**
- `.zshrc` references `$ZSH/oh-my-zsh.sh` but directory doesn't exist

**Solutions:**

```bash
# 1. Install Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 2. Or comment out Oh-My-Zsh sourcing in .zshrc
# Edit ~/.zshrc and comment: # source $ZSH/oh-my-zsh.sh

# 3. Re-link dotfiles
cd ~/dotfiles
bash scripts/link-dotfiles.sh
```

---

## Package Installation Issues

### Problem: `install-packages.sh` script fails

**Symptoms:**
- Script exits with error
- "command not found" errors

**Solutions:**

```bash
# 1. Make script executable
chmod +x ~/dotfiles/scripts/install-packages.sh

# 2. Run with bash explicitly
bash ~/dotfiles/scripts/install-packages.sh all

# 3. Update system first
sudo pacman -Syu

# 4. Check if pacman is working
sudo pacman -Ss vim  # Try to search

# 5. Run step-by-step
sudo pacman -S --needed base-devel
sudo pacman -S git
cd ~/dotfiles
bash scripts/install-packages.sh pacman
bash scripts/install-packages.sh yay
bash scripts/install-packages.sh npm
```

### Problem: Yay installation fails

**Symptoms:**
- `yay: command not found`
- Error during yay compilation

**Solutions:**

```bash
# 1. Install dependencies first
sudo pacman -S base-devel git

# 2. Manual yay installation
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si
cd ~

# 3. Verify installation
yay --version

# 4. If still fails, try paru instead
sudo pacman -S paru
paru -S package-name  # Use paru instead of yay
```

### Problem: Package not found (404 error)

**Symptoms:**
- "error: target not found: package-name"
- Package not in official repos

**Solutions:**

```bash
# 1. Search for correct name
pacman -Ss search-term
yay -Ss search-term  # Also search AUR

# 2. Update package database
sudo pacman -Sy
yay -Sy

# 3. Install from AUR if not in official repos
yay -S aur-package-name

# 4. Check if you're on correct architecture
uname -m  # Should be x86_64 for most systems

# 5. Edit package list - remove packages not available
nano ~/dotfiles/arch-packages-pacman.txt
# Remove lines for unavailable packages
# Then try again
bash ~/dotfiles/scripts/install-packages.sh pacman
```

### Problem: npm install fails with permission error

**Symptoms:**
- "npm ERR! code EACCES"
- "npm ERR! permission denied"

**Solutions:**

```bash
# 1. Fix npm permissions (recommended)
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH
# Add to ~/.zshrc or ~/.bashrc:
# export PATH=~/.npm-global/bin:$PATH

# 2. Or use sudo (not recommended)
sudo npm install -g package-name

# 3. Fix existing installation
sudo chown -R $(whoami) ~/.npm

# 4. Clear npm cache
npm cache clean --force

# 5. Retry installation
npm install -g package-name
```

---

## Git & SSH Issues

### Problem: Git not configured

**Symptoms:**
- `fatal: not a git repository`
- Git commands not working

**Solutions:**

```bash
# 1. Configure git user
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# 2. Check configuration
git config --list

# 3. Link git config from repo
cd ~/dotfiles
bash scripts/link-dotfiles.sh

# 4. Verify symlink
cat ~/.gitconfig
```

### Problem: SSH authentication fails

**Symptoms:**
- `Permission denied (publickey)`
- `Could not resolve hostname`
- SSH connection hangs

**Solutions:**

```bash
# 1. Test SSH connection (verbose)
ssh -vvv git@github.com
ssh -vvv github-nuoa

# 2. Check SSH keys exist
ls -la ~/.ssh/
# Should see: id_ed25519, id_ed25519.pub, config, known_hosts

# 3. Generate missing keys
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "your.email@example.com"

# 4. Check key permissions
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config

# 5. Add keys to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 6. Test SSH again
ssh -T git@github.com

# 7. If using multiple keys
ssh-add -l  # List loaded keys
ssh-add ~/.ssh/id_rsa  # Add RSA key if needed
```

### Problem: SSH config symlink issues

**Symptoms:**
- "Bad permissions on config file"
- SSH using wrong key

**Solutions:**

```bash
# 1. Check permissions
ls -la ~/.ssh/config
# Should be: -rw------- (600)

# 2. Fix permissions
chmod 600 ~/.ssh/config

# 3. Check symlink
readlink ~/.ssh/config
# Should point to: ~/dotfiles/.ssh/config

# 4. Re-link SSH config
cd ~/dotfiles
bash scripts/link-dotfiles.sh

# 5. Verify SSH config syntax
ssh -G github.com  # Displays effective config for host
ssh -G github-nuoa
```

### Problem: Known_hosts entries causing issues

**Symptoms:**
- "Host key verification failed"
- "Offending key in known_hosts"

**Solutions:**

```bash
# 1. Remove problematic entry
ssh-keyscan -H ssh.github.com >> ~/.ssh/known_hosts 2>/dev/null

# 2. Or remove all entries for a host
ssh-keygen -R ssh.github.com
ssh-keygen -R github.com

# 3. Accept new keys automatically on first connection
# (Configured in repo's .ssh/config with StrictHostKeyChecking accept-new)

# 4. Manually verify and add
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
ssh -T git@github.com
```

---

## AWS Configuration Issues

### Problem: AWS CLI not working

**Symptoms:**
- `aws: command not found`
- `Unable to locate credentials`

**Solutions:**

```bash
# 1. Check if AWS CLI installed
which aws
aws --version

# 2. Install if missing
sudo pacman -S aws-cli

# 3. Configure AWS credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format

# 4. Or manually create credentials file
mkdir -p ~/.aws
cat > ~/.aws/credentials << 'EOF'
[default]
aws_access_key_id = YOUR_KEY
aws_secret_access_key = YOUR_SECRET
EOF
chmod 600 ~/.aws/credentials

# 5. Test credentials
aws sts get-caller-identity
```

### Problem: AWS credentials file permissions wrong

**Symptoms:**
- "AWS credentials file must be readable only by owner"

**Solutions:**

```bash
# 1. Fix permissions
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
chmod 700 ~/.aws

# 2. Verify
ls -la ~/.aws/

# 3. Test again
aws sts get-caller-identity
```

### Problem: Wrong AWS profile being used

**Symptoms:**
- AWS commands using wrong credentials
- Wrong region selected

**Solutions:**

```bash
# 1. List profiles
aws configure list
aws sts get-caller-identity

# 2. Use specific profile
AWS_PROFILE=profile-name aws s3 ls

# 3. Set default profile in shell
export AWS_PROFILE=profile-name
# Add to ~/.zshrc or ~/.bashrc

# 4. Check config file
cat ~/.aws/config
cat ~/.aws/credentials
```

---

## Copilot CLI & MCP Issues

### Problem: Copilot CLI not installed

**Symptoms:**
- `copilot: command not found`

**Solutions:**

```bash
# 1. Check installation
npm list -g @github/copilot

# 2. Install if missing
npm install -g @github/copilot@latest

# 3. Verify
copilot --version

# 4. If npm install fails, see npm permission issues section
```

### Problem: MCP servers not configured

**Symptoms:**
- Copilot doesn't have context
- MCP errors in logs

**Solutions:**

```bash
# 1. Setup MCP servers
cd ~/dotfiles
bash scripts/setup-mcp-servers.sh

# 2. Check configuration files
cat ~/.copilot/config.json
cat ~/.copilot/mcp_servers.json

# 3. Verify MCP packages installed
npm list -g @modelcontextprotocol/server-filesystem

# 4. Install missing packages
npm install -g @modelcontextprotocol/server-filesystem
npm install -g @modelcontextprotocol/server-git
npm install -g @modelcontextprotocol/server-bash

# 5. Restart shell and try copilot
exec zsh
copilot --version
```

### Problem: Invalid MCP JSON configuration

**Symptoms:**
- JSON parse errors
- MCP servers not starting

**Solutions:**

```bash
# 1. Validate JSON syntax
python3 -m json.tool ~/.copilot/mcp_servers.json

# 2. Or use jq
jq . ~/.copilot/mcp_servers.json

# 3. Recreate configuration
rm ~/.copilot/mcp_servers.json
cd ~/dotfiles
bash scripts/setup-mcp-servers.sh

# 4. Check file permissions
chmod 644 ~/.copilot/config.json
chmod 644 ~/.copilot/mcp_servers.json
```

---

## WSL-Specific Issues

### Problem: WSL processes slow or hanging

**Symptoms:**
- Commands take very long
- CPU/memory usage high
- WSL unresponsive

**Solutions:**

```bash
# 1. Check WSL resources
free -h  # Memory usage
df -h    # Disk usage
ps aux   # Running processes

# 2. Restart WSL from Windows PowerShell (as admin)
wsl --terminate Arch  # or your distro name

# 3. Update WSL kernel
wsl --update

# 4. Check for disk space issues
du -sh ~/*
df -h /

# 5. Clear package cache
sudo pacman -Sc

# 6. Optimize WSL settings - Create ~/.wslconfig (in Windows user home)
# [interop]
# enabled=true
# [wsl2]
# memory=4GB
# processors=4
```

### Problem: File permissions different on /mnt/c/

**Symptoms:**
- Files always appear as 777 (world-writable)
- Permission changes don't stick

**Solutions:**

```bash
# 1. Mount Windows drives with proper options
# In Windows: Create .wslconfig in %USERPROFILE%
# [interop]
# appendWindowsPath=true
# [wsl2]
# kernelCommandLine = vsyscall=emulate

# 2. Or mount manually in WSL
sudo mount -t drvfs C: /mnt/c -o metadata,uid=1000,gid=1000,umask=022

# 3. Work with files in WSL filesystem (/home) instead of /mnt/c
# This will have proper permissions

# 4. Check mount options
mount | grep /mnt/c
```

### Problem: Cannot find some commands from Windows

**Symptoms:**
- Commands like `notepad` not working
- Windows programs not accessible

**Solutions:**

```bash
# 1. Check if Windows interop is enabled
grep -i interop ~/.wslconfig

# 2. Explicitly call from Windows
/mnt/c/Windows/System32/cmd.exe /c notepad

# 3. Use WSL utilities
wslview /path/to/file  # Open in Windows default app

# 4. Add Windows PATH to WSL PATH (in .zshrc)
export PATH="$PATH:/mnt/c/Windows/System32"
```

---

## General Debugging

### Enable debug mode for scripts

```bash
# Add debug flag to scripts
bash -x ~/dotfiles/scripts/install-packages.sh pacman

# Or add to script
set -x  # Enable debug output
set -e  # Exit on error
```

### Check system logs

```bash
# View recent errors
journalctl -xe  # System journal (may not work fully on WSL)

# Check pacman log
tail -f /var/log/pacman.log

# WSL logs (from Windows)
Get-Content "$env:LOCALAPPDATA\Packages\Archlinux.Arch_79rhkp1fndgsc\LocalState\rootfs\var\log\pacman.log"
```

### Common error codes

| Code | Meaning | Solution |
|------|---------|----------|
| 1 | General error | Check error message, enable debug mode |
| 127 | Command not found | Check PATH, verify installation |
| 2 | Misuse of shell command | Check syntax, verify script |
| 255 | SSH connection failed | Check SSH keys and config |
| 70 | Internal software error | Reinstall package, try updates |

---

## Getting Help

If issues persist:

1. **Check the setup guide:** [SETUP_GUIDE.md](./SETUP_GUIDE.md)
2. **Review architecture:** [ARCHITECTURE.md](./ARCHITECTURE.md)
3. **Enable debug mode** and capture full output
4. **Search Arch Wiki:** https://wiki.archlinux.org/
5. **Check Copilot CLI issues:** https://github.com/github/copilot-cli/issues
6. **Ask for help:** Create an issue or reach out with full system info

---

**Last Updated:** 2026-03-16
