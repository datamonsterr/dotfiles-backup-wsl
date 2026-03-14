# Dotfiles Backup

Backup of configuration files from WSL2 Ubuntu 20.04 before migration to Arch Linux WSL2.

## Restore Instructions

1. **Clone this repo:**
   ```bash
   git clone git@github.com:datamonsterr/dotfiles-backup-wsl.git ~/dotfiles
   ```

2. **Restore Configs:**
   Copy files to your home directory:
   ```bash
   cp ~/dotfiles/.zshrc ~/.zshrc
   cp ~/dotfiles/.bashrc ~/.bashrc
   cp ~/dotfiles/.gitconfig ~/.gitconfig
   mkdir -p ~/.ssh && cp ~/dotfiles/.ssh/config ~/.ssh/
   mkdir -p ~/.aws && cp ~/dotfiles/.aws/config ~/.aws/
   ```

3. **Install Packages:**
   Check `apt_packages.txt` (for reference) and `npm_packages.txt`.
   
   For Arch Linux, you'll use `pacman` or `yay`.
   
   Common packages to install:
   ```bash
   sudo pacman -S git zsh neovim ...
   ```

4. **Secrets:**
   Restore your SSH keys and AWS credentials manually from your secure backup (they are NOT in this repo).
