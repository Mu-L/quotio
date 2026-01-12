# quotio-cli

Cross-platform CLI tool for managing CLIProxyAPI - the local proxy server for AI coding agents.

quotio-cli is the command-line companion to the Quotio macOS app, allowing you to manage quota tracking, authentication, and agent configuration on any platform that supports the Bun runtime.

## Features

- **Quota Management**: Track usage across multiple AI providers including Claude Code, Gemini CLI, and GitHub Copilot.
- **Authentication**: Manage OAuth tokens and API keys for your AI accounts.
- **Proxy Control**: Start, stop, and monitor the local CLIProxyAPI server instance.
- **Embedded Proxy Binary**: CLIProxyAPI binary bundled for standalone operation.
- **Agent Configuration**: Automatically detect and configure CLI tools to use the proxy.
- **Cross-Platform**: Runs on macOS (ARM64/x64), Linux (ARM64/x64), and Windows (x64).

## Installation

### Prerequisites

- [Bun](https://bun.sh) runtime (version 1.1.0 or higher)

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/nguyenphutrong/quotio.git
   cd quotio/quotio-cli
   ```

2. Install dependencies:
   ```bash
   bun install
   ```

3. Download the proxy binary for your platform:
   ```bash
   bun run download-proxy:current
   # Or for all platforms:
   bun run download-proxy -- --all
   ```

4. Build the binary:
   ```bash
   bun run build
   # Or for all platforms:
   bun run build:all
   ```

The binary will be available at `./dist/quotio` (or `./dist/quotio-{platform}` for multi-platform builds).

## Usage

Run the CLI using the built binary:

```bash
./dist/quotio <command> [options]
```

Or directly via Bun during development:

```bash
bun run dev <command> [options]
```

### Global Options

- `--format <type>`: Output format (table, json, plain). Default: table.
- `--verbose, -v`: Enable verbose output.
- `--base-url <url>`: CLIProxyAPI base URL. Default: http://localhost:8217.
- `--help, -h`: Show help for a command.

## Commands

### Manage Quota

View and manage your AI provider quotas.

```bash
# View all quotas
quotio quota list

# Check specific provider
quotio quota status --provider claude
```

### Authentication

Manage your accounts and tokens.

```bash
# List authenticated accounts
quotio auth list

# Login to a new provider
quotio auth login --provider gemini
```

### Proxy Control

Manage the local proxy server process and binary.

```bash
# Install the proxy binary
quotio proxy install

# Start the proxy server
quotio proxy start
# Start on a custom port
quotio proxy start --port 9000

# Stop the proxy server
quotio proxy stop

# Restart the proxy server
quotio proxy restart

# Check proxy status (binary path, process PID, health)
quotio proxy status

# Quick health check
quotio proxy health

# Remove the proxy binary
quotio proxy uninstall
```

### Agent Configuration

Configure your CLI tools to use the proxy.

```bash
# Detect installed agents
quotio agent detect

# Configure a specific agent
quotio agent configure --name claude-code
```

## Supported Providers

- Claude Code
- Gemini CLI
- GitHub Copilot
- Cursor (IDE)
- Trae (IDE)
- Kiro (CodeWhisperer)
- Antigravity
- Codex (OpenAI)

## Development

### Scripts

- `bun run dev`: Run the CLI in development mode.
- `bun run build`: Compile the CLI into a single binary for the current platform.
- `bun run build:all`: Compile the CLI for all supported platforms.
- `bun run download-proxy`: Download the CLIProxyAPI binary for the current platform.
- `bun run lint`: Run the linter to check for code style issues.
- `bun run format`: Format the code using the project's style guide.

### Project Structure

- `src/cli`: Command definitions and handlers.
- `src/models`: TypeScript interfaces and data models.
- `src/services`: Core business logic.
  - `proxy-binary`: Management of the embedded CLIProxyAPI binary.
  - `proxy-process`: Lifecycle management for the proxy server process.
- `src/utils`: Helper functions.

## License

This project is licensed under the MIT License.
