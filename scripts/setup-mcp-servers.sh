#!/bin/bash
# Setup MCP (Model Context Protocol) servers for Copilot CLI
# Creates configuration for connecting Copilot to local tools and services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$SCRIPT_DIR"
HOME_DIR="$HOME"
COPILOT_CONFIG="$HOME_DIR/.copilot"
MCP_CONFIG="$COPILOT_CONFIG/mcp_servers.json"

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

create_mcp_config() {
  log_info "Creating MCP servers configuration..."
  
  mkdir -p "$COPILOT_CONFIG"
  
  # Create MCP servers config file
  cat > "$MCP_CONFIG" << 'EOF'
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": ["-e", "require('@modelcontextprotocol/server-filesystem').main()"],
      "env": {
        "MCP_FILESYSTEM_PATH": "/home/dat"
      }
    },
    "git": {
      "command": "node",
      "args": ["-e", "require('@modelcontextprotocol/server-git').main()"],
      "env": {
        "GIT_REPOSITORY": "/home/dat/dotfiles-backup-wsl"
      }
    },
    "bash": {
      "command": "bash",
      "args": ["-c", "node -e 'require(\"@modelcontextprotocol/server-bash\").main()'"]
    },
    "stdio": {
      "command": "node",
      "args": ["-e", "require('@modelcontextprotocol/server-stdio').main()"]
    }
  },
  "settings": {
    "debug": false,
    "timeout": 30000
  }
}
EOF
  
  log_success "MCP config created at: $MCP_CONFIG"
}

setup_mcp_npm_packages() {
  log_info "Setting up MCP npm packages..."
  
  if ! command -v npm &> /dev/null; then
    log_warn "npm not found, skipping MCP npm setup"
    return
  fi
  
  local mcp_packages=(
    "@modelcontextprotocol/server-filesystem"
    "@modelcontextprotocol/server-git"
    "@modelcontextprotocol/server-bash"
    "@modelcontextprotocol/server-stdio"
  )
  
  for pkg in "${mcp_packages[@]}"; do
    log_info "Checking for $pkg..."
    if npm list -g "$pkg" &>/dev/null; then
      log_success "$pkg already installed"
    else
      log_info "Installing $pkg..."
      npm install -g "$pkg"
      log_success "$pkg installed"
    fi
  done
}

create_mcp_server_wrapper() {
  log_info "Creating MCP server wrapper scripts..."
  
  local scripts_dir="$REPO_ROOT/scripts"
  
  # Bash MCP server wrapper
  cat > "$scripts_dir/mcp-bash-server.sh" << 'BASH_EOF'
#!/bin/bash
# MCP Bash Server - allows Copilot to execute bash commands safely
# Usage: node -r ./mcp-bash-server.js

node -e '
const { Server } = require("@modelcontextprotocol/sdk/server/index.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");
const { CallToolRequestSchema, TextContent } = require("@modelcontextprotocol/sdk/types.js");
const { execSync } = require("child_process");

const server = new Server({
  name: "bash-mcp-server",
  version: "1.0.0",
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === "execute") {
    const cmd = request.params.arguments?.command;
    if (!cmd) throw new Error("No command specified");
    
    try {
      const result = execSync(cmd, { encoding: "utf-8", maxBuffer: 10 * 1024 * 1024 });
      return {
        content: [{ type: "text", text: result || "(no output)" }],
      };
    } catch (error) {
      return {
        content: [{ type: "text", text: `Error: ${error.message}` }],
        isError: true,
      };
    }
  }
  throw new Error(`Unknown tool: ${request.params.name}`);
});

const transport = new StdioServerTransport();
server.connect(transport);
'
BASH_EOF
  
  chmod +x "$scripts_dir/mcp-bash-server.sh"
  log_success "MCP bash server wrapper created"
}

create_copilot_cli_config() {
  log_info "Creating Copilot CLI configuration..."
  
  # Check if copilot config exists
  if [ ! -d "$COPILOT_CONFIG" ]; then
    mkdir -p "$COPILOT_CONFIG"
  fi
  
  # Create Claude configuration
  cat > "$COPILOT_CONFIG/config.json" << 'EOF'
{
  "model": "claude-3.5-sonnet",
  "temperature": 0.7,
  "maxTokens": 8096,
  "mcpServersEnabled": true,
  "debug": false,
  "cacheDir": "/tmp/copilot-cache"
}
EOF
  
  log_success "Copilot CLI config created at: $COPILOT_CONFIG/config.json"
}

verify_mcp_setup() {
  log_info "Verifying MCP setup..."
  
  if [ -f "$MCP_CONFIG" ]; then
    log_success "✓ MCP servers config file exists"
  else
    log_warn "⚠ MCP servers config not found"
  fi
  
  if [ -d "$COPILOT_CONFIG" ]; then
    log_success "✓ Copilot config directory exists"
  else
    log_warn "⚠ Copilot config directory not found"
  fi
}

main() {
  log_info "Setting up MCP servers for Copilot CLI..."
  
  create_mcp_config
  create_copilot_cli_config
  setup_mcp_npm_packages
  create_mcp_server_wrapper
  verify_mcp_setup
  
  log_success "MCP setup complete!"
  log_info "Configuration saved to: $COPILOT_CONFIG"
  log_info "Next: Configure Copilot CLI to use these MCP servers"
}

main "$@"
