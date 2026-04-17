# Model Context Protocol (MCP) Servers Configuration

This document explains the Model Context Protocol (MCP) integration with Copilot CLI and how to configure it properly.

## What is MCP?

Model Context Protocol is a standardized way for AI applications (like Copilot) to interact with external tools and data sources safely. MCP servers provide:

- **Filesystem access** - Allow AI to read and understand code
- **Git integration** - Provide repository history and diffs
- **Command execution** - Safe bash command execution
- **Custom integrations** - Any tool you need

## Current MCP Configuration

### Installed MCP Servers

The `setup-mcp-servers.sh` script installs and configures:

```json
{
  "filesystem": {
    "description": "Access to filesystem within /home/dat",
    "command": "node",
    "module": "@modelcontextprotocol/server-filesystem"
  },
  "git": {
    "description": "Git repository access",
    "command": "node",
    "module": "@modelcontextprotocol/server-git"
  },
  "bash": {
    "description": "Safe bash command execution",
    "command": "bash",
    "module": "@modelcontextprotocol/server-bash"
  },
  "stdio": {
    "description": "Standard I/O operations",
    "command": "node",
    "module": "@modelcontextprotocol/server-stdio"
  }
}
```

## Configuration Files

### ~/.copilot/config.json
Main Copilot CLI configuration
```json
{
  "model": "claude-3.5-sonnet",
  "temperature": 0.7,
  "maxTokens": 8096,
  "mcpServersEnabled": true,
  "debug": false,
  "cacheDir": "/tmp/copilot-cache"
}
```

**Settings:**
- `model`: LLM model to use (claude-3.5-sonnet, gpt-4, etc.)
- `temperature`: 0-1, higher = more creative
- `maxTokens`: Max response length
- `mcpServersEnabled`: Enable/disable MCP integration
- `debug`: Enable detailed logging
- `cacheDir`: Cache directory for MCP responses

### ~/.copilot/mcp_servers.json
MCP servers configuration

**Structure:**
```json
{
  "mcpServers": {
    "server-name": {
      "command": "node|bash|python|...",
      "args": ["arg1", "arg2"],
      "env": {
        "ENV_VAR": "value"
      }
    }
  },
  "settings": {
    "debug": false,
    "timeout": 30000
  }
}
```

## Using MCP Servers

### With Copilot CLI

```bash
# Ask Copilot to use MCP context
copilot --use-mcp "Explain the current git commits in this repo"

# Copilot will:
# 1. Use git MCP server to get commit history
# 2. Use filesystem MCP server to read relevant files
# 3. Generate informed response

# List available MCP tools
copilot --list-mcp-tools

# Use specific MCP server
copilot --mcp filesystem --help
```

### Direct MCP Server Usage

```bash
# Start MCP filesystem server
node -e "require('@modelcontextprotocol/server-filesystem').main()"

# In another terminal, connect to it
# (Usually handled by Copilot CLI automatically)

# Test git server
node -e "require('@modelcontextprotocol/server-git').main()"
```

## Adding Custom MCP Servers

### Step 1: Create Custom Server

Example: A Python MCP server for custom tools

```bash
# Create server script
cat > ~/.copilot/servers/custom-tools.py << 'EOF'
#!/usr/bin/env python3
import json
import sys

class CustomMCPServer:
    def __init__(self):
        self.tools = {
            "fetch-weather": "Get weather for a location",
            "translate-text": "Translate text between languages"
        }
    
    def list_tools(self):
        return {
            "type": "list_tools",
            "tools": self.tools
        }
    
    def call_tool(self, name, args):
        if name == "fetch-weather":
            return {"result": f"Weather for {args.get('location')}: Sunny"}
        elif name == "translate-text":
            return {"result": f"Translated: {args.get('text')}"}
        return {"error": "Unknown tool"}

server = CustomMCPServer()

# Read from stdin
while True:
    try:
        line = sys.stdin.readline()
        if not line:
            break
        request = json.loads(line)
        
        if request["method"] == "list_tools":
            response = server.list_tools()
        elif request["method"] == "call_tool":
            response = server.call_tool(
                request["params"]["name"],
                request["params"]["arguments"]
            )
        else:
            response = {"error": "Unknown method"}
        
        print(json.dumps(response))
        sys.stdout.flush()
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.stdout.flush()
EOF

chmod +x ~/.copilot/servers/custom-tools.py
```

### Step 2: Register in config

```bash
# Update ~/.copilot/mcp_servers.json
jq '.mcpServers.custom = {
  "command": "python3",
  "args": ["/home/dat/.copilot/servers/custom-tools.py"]
}' ~/.copilot/mcp_servers.json > /tmp/mcp.json && mv /tmp/mcp.json ~/.copilot/mcp_servers.json
```

### Step 3: Test Custom Server

```bash
# List tools
copilot --list-mcp-tools | grep custom

# Use custom tool
copilot --use-mcp custom "Use the fetch-weather tool for San Francisco"
```

## Security & Permissions

### MCP Server Security

1. **Filesystem access**: Limited to `/home/dat` by default
   - Modify in config to restrict further
   - Never include `/`, `/etc`, `/root`

2. **Command execution**: Only bash commands via `@modelcontextprotocol/server-bash`
   - Copilot cannot modify system files
   - Commands run as current user
   - Can be further restricted with allowlists

3. **Git access**: Read-only by default
   - Cannot push to repositories
   - Only reads history and metadata

4. **Secrets**: Never pass secrets in MCP config
   - Use environment variables from shell
   - AWS credentials loaded via IAM
   - SSH keys from ssh-agent

### Running Securely

```bash
# Create restricted user for MCP (optional)
sudo useradd -m -s /sbin/nologin copilot-mcp

# Create restricted filesystem access
mkdir -p /opt/copilot-mcp/workspace
sudo chown copilot-mcp:copilot-mcp /opt/copilot-mcp/workspace

# Run MCP server as restricted user
sudo -u copilot-mcp node /opt/copilot-mcp/servers/filesystem.js
```

## Performance Tuning

### Increase Timeout for Large Repos

```json
{
  "settings": {
    "timeout": 60000,
    "maxResponseSize": "50MB"
  }
}
```

### Cache MCP Responses

```bash
# Enable response caching
export MCP_CACHE_RESPONSES=true
export MCP_CACHE_DIR=/tmp/copilot-mcp-cache
```

### Reduce Filesystem Scope

```json
{
  "mcpServers": {
    "filesystem": {
      "env": {
        "MCP_FILESYSTEM_PATH": "/home/dat/dotfiles-backup-wsl",
        "MCP_FILESYSTEM_MAXDEPTH": "5"
      }
    }
  }
}
```

## Troubleshooting MCP

### Check if MCP servers are running

```bash
# List running processes
ps aux | grep mcp

# Test filesystem server
curl http://localhost:3000/health 2>/dev/null

# Check logs
journalctl -u copilot-mcp -f
```

### Enable MCP debugging

```bash
# In ~/.copilot/config.json
{
  "debug": true,
  "mcpDebugLog": "/tmp/mcp-debug.log"
}

# Run Copilot with verbose output
copilot --verbose --use-mcp "test query"

# Check debug log
tail -f /tmp/mcp-debug.log
```

### MCP server crashes

```bash
# Check error messages
journalctl -xe | grep mcp

# Restart MCP server
pkill -f "@modelcontextprotocol"
cd ~/dotfiles
bash scripts/setup-mcp-servers.sh

# Verify configuration
python3 -m json.tool ~/.copilot/mcp_servers.json
```

### Copilot not connecting to MCP

```bash
# 1. Verify MCP is enabled
grep "mcpServersEnabled" ~/.copilot/config.json

# 2. Check Copilot CLI version
copilot --version

# 3. Update Copilot CLI
npm install -g @github/copilot@latest

# 4. Restart shell
exec zsh

# 5. Test connection
copilot --list-mcp-tools
```

## MCP Best Practices

1. **Start with official servers**: Filesystem, git, bash are stable and tested
2. **Limit scope**: Only expose directories you want Copilot to access
3. **Monitor security**: Review what commands Copilot executes
4. **Use timeouts**: Prevent hanging on large operations
5. **Cache responses**: Improve performance for repeated queries
6. **Version your servers**: Keep MCP packages updated
7. **Test thoroughly**: Verify custom servers before production use

## Advanced: Writing a Custom MCP Server

### Node.js Example

```typescript
// ~/.copilot/servers/docker-mcp.ts
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { execSync } from "child_process";

const server = new Server({
  name: "docker-mcp-server",
  version: "1.0.0",
});

server.tool("list-containers", "List all Docker containers", async () => {
  const output = execSync("docker ps -a --format json").toString();
  return { contents: [{ type: "text", text: output }] };
});

server.tool("container-logs", "Get logs from a container", async (params) => {
  const output = execSync(`docker logs ${params.container}`).toString();
  return { contents: [{ type: "text", text: output }] };
});

// Server initialization
server.connect(stdio);
```

### Python Example

```python
# ~/.copilot/servers/analytics-mcp.py
from mcp.server import Server
import pandas as pd

server = Server("analytics-mcp-server")

@server.tool()
def analyze_csv(filepath: str) -> dict:
    """Analyze a CSV file"""
    df = pd.read_csv(filepath)
    return {
        "shape": df.shape,
        "columns": df.columns.tolist(),
        "dtypes": df.dtypes.to_dict(),
        "summary": df.describe().to_dict()
    }

@server.tool()
def generate_report(data_source: str) -> str:
    """Generate analysis report"""
    df = pd.read_csv(data_source)
    return f"Report: {len(df)} records analyzed"

if __name__ == "__main__":
    server.run()
```

---

## Related Documentation

- [SETUP_GUIDE.md](./SETUP_GUIDE.md) - Complete setup instructions including MCP
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture and components
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - General troubleshooting guide

## Resources

- **MCP Documentation**: https://modelcontextprotocol.io/
- **Copilot CLI GitHub**: https://github.com/github/copilot-cli
- **Node.js MCP SDK**: https://github.com/modelcontextprotocol/node-sdk
- **Python MCP SDK**: https://github.com/modelcontextprotocol/python-sdk

---

**Last Updated:** 2026-03-16
