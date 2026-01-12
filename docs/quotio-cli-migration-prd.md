# Quotio CLI Migration PRD

**Version:** 1.0.0  
**Date:** 2026-01-12  
**Status:** Draft  
**Author:** Quotio Team

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement](#2-problem-statement)
3. [Goals & Non-Goals](#3-goals--non-goals)
4. [Target Users](#4-target-users)
5. [Technical Architecture](#5-technical-architecture)
6. [Data Models](#6-data-models)
7. [CLI Command Specification](#7-cli-command-specification)
8. [Implementation Phases](#8-implementation-phases)
9. [Migration Guide](#9-migration-guide)
10. [Testing Strategy](#10-testing-strategy)
11. [Risk Assessment](#11-risk-assessment)
12. [Success Metrics](#12-success-metrics)
13. [Appendix](#13-appendix)

---

## 1. Executive Summary

### 1.1 Overview

Migrate Quotio's business logic from a macOS-only Swift application to a standalone cross-platform CLI binary (`quotio-cli`) built with **Bun + TypeScript**. The CLI will handle all core functionality (quota fetching, agent configuration, proxy management) while platform-specific GUI wrappers communicate via IPC.

### 1.2 Current State

| Component | Technology | Platform |
|-----------|------------|----------|
| **Quotio App** | Swift 6 / SwiftUI | macOS only |
| **CLIProxyAPI** | Go binary | macOS, Linux, Windows |
| **Business Logic** | Embedded in Swift | macOS only |

### 1.3 Target State

| Component | Technology | Platform |
|-----------|------------|----------|
| **quotio-cli** | Bun + TypeScript | macOS, Linux, Windows |
| **Quotio macOS** | Swift / SwiftUI (thin wrapper) | macOS |
| **Quotio Windows** | Electron / Tauri (future) | Windows |
| **Quotio Linux** | GTK / Electron (future) | Linux |

### 1.4 Key Benefits

- **Multi-platform**: Same logic runs on macOS, Windows, Linux
- **Maintainability**: Single TypeScript codebase vs duplicating Swift/Kotlin/C#
- **Developer Experience**: Headless CLI for power users and automation
- **Faster Iteration**: TypeScript enables rapid feature development
- **Community**: Easier contributions from TypeScript developers

---

## 2. Problem Statement

### 2.1 Current Limitations

1. **Platform Lock-in**: All business logic is in Swift, limiting Quotio to macOS
2. **Code Duplication**: Building for Windows/Linux requires rewriting in different languages
3. **No Headless Mode**: Users cannot automate quota checks or agent configuration via scripts
4. **Maintenance Burden**: Two codebases (Swift GUI + Go proxy) with overlapping responsibilities

### 2.2 User Pain Points

| User Type | Pain Point |
|-----------|------------|
| **Linux Users** | Cannot use Quotio at all |
| **Windows Users** | Cannot use Quotio at all |
| **DevOps/CI** | No automation support for quota monitoring |
| **Power Users** | Must use GUI for simple tasks |

---

## 3. Goals & Non-Goals

### 3.1 Goals

| Priority | Goal |
|----------|------|
| **P0** | Extract all business logic into `quotio-cli` |
| **P0** | Support macOS, Linux, Windows from single codebase |
| **P0** | Maintain feature parity with current macOS app |
| **P1** | Enable headless operation for CI/automation |
| **P1** | Provide IPC interface for GUI wrappers |
| **P2** | Improve quota fetching speed with parallel execution |
| **P2** | Add structured JSON output for scripting |

### 3.2 Non-Goals

| Item | Reason |
|------|--------|
| Replace CLIProxyAPI | Go proxy remains the core; CLI wraps it |
| Build Windows/Linux GUIs | Future phase; CLI-first approach |
| Change authentication flows | OAuth flows remain in CLIProxyAPI |
| Support mobile platforms | Out of scope |

---

## 4. Target Users

### 4.1 User Personas

#### Developer (Primary)

- Uses multiple AI coding assistants (Claude Code, Cursor, Gemini CLI)
- Wants unified quota monitoring across providers
- May work on macOS, Linux, or Windows
- Comfortable with CLI tools

#### DevOps Engineer

- Manages AI tool deployment for teams
- Needs automated quota monitoring and alerts
- Integrates with CI/CD pipelines
- Requires JSON/machine-readable output

#### Power User

- Prefers terminal over GUI
- Wants scriptable configuration
- Uses shell aliases and automation

### 4.2 Usage Scenarios

```
┌─────────────────────────────────────────────────────────────┐
│                     Usage Scenarios                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  macOS User        Linux User        Windows User           │
│      │                 │                  │                  │
│      ▼                 ▼                  ▼                  │
│  ┌────────┐       ┌────────┐        ┌────────┐              │
│  │ Quotio │       │Terminal│        │  CLI   │              │
│  │  App   │       │  CLI   │        │  Only  │              │
│  └───┬────┘       └───┬────┘        └───┬────┘              │
│      │                │                  │                   │
│      └────────────────┼──────────────────┘                   │
│                       ▼                                      │
│              ┌────────────────┐                              │
│              │   quotio-cli   │                              │
│              │ (Bun binary)   │                              │
│              └───────┬────────┘                              │
│                      │                                       │
│                      ▼                                       │
│              ┌────────────────┐                              │
│              │  CLIProxyAPI   │                              │
│              │  (Go binary)   │                              │
│              └────────────────┘                              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Technical Architecture

### 5.1 System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        System Architecture                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────┐     ┌──────────────────┐                      │
│  │   Quotio macOS   │     │  Future: Win/Lin │                      │
│  │   (SwiftUI)      │     │  GUI Wrappers    │                      │
│  └────────┬─────────┘     └────────┬─────────┘                      │
│           │                        │                                 │
│           │     IPC (Unix Socket / Named Pipe)                      │
│           │                        │                                 │
│           ▼                        ▼                                 │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │                      quotio-cli                           │       │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐ │       │
│  │  │   Commands  │ │   Services  │ │    IPC Server       │ │       │
│  │  │  (Bunli)    │ │  (Business) │ │ (Bun.serve unix)    │ │       │
│  │  └─────────────┘ └─────────────┘ └─────────────────────┘ │       │
│  └────────────────────────────┬─────────────────────────────┘       │
│                               │                                      │
│                               ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │                     CLIProxyAPI                           │       │
│  │  Management API (HTTP :8317)    Proxy API (HTTP :8317)   │       │
│  └────────────────────────────┬─────────────────────────────┘       │
│                               │                                      │
│                               ▼                                      │
│  ┌──────────────────────────────────────────────────────────┐       │
│  │              AI Provider APIs (External)                  │       │
│  │  Anthropic │ Google │ OpenAI │ GitHub │ Cursor │ ...     │       │
│  └──────────────────────────────────────────────────────────┘       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 5.2 Technology Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| **Runtime** | Bun 1.1+ | Fast startup, native TS, cross-compile |
| **CLI Framework** | Bunli / native parseArgs | Type-safe, minimal deps |
| **HTTP Client** | Native `fetch` | Built-in, no deps |
| **IPC** | Unix sockets (POSIX) / Named pipes (Windows) | Fast, local-only |
| **Config** | TOML + JSON | Human-readable + machine-readable |
| **SQLite** | better-sqlite3 / bun:sqlite | For Cursor/Trae DB reads |
| **Testing** | Bun test | Built-in, fast |

### 5.3 Directory Structure

```
quotio-cli/
├── src/
│   ├── index.ts                 # Entry point
│   ├── cli/
│   │   ├── commands/            # Command handlers
│   │   │   ├── quota.ts         # quota fetch, list
│   │   │   ├── agent.ts         # agent detect, configure
│   │   │   ├── proxy.ts         # proxy start, stop, status
│   │   │   ├── auth.ts          # auth login, logout, list
│   │   │   ├── config.ts        # config get, set
│   │   │   └── daemon.ts        # daemon start, stop (IPC server)
│   │   └── index.ts             # CLI router
│   ├── services/
│   │   ├── management-api.ts    # CLIProxyAPI HTTP client
│   │   ├── quota-fetchers/
│   │   │   ├── claude.ts
│   │   │   ├── cursor.ts
│   │   │   ├── copilot.ts
│   │   │   ├── gemini.ts
│   │   │   ├── codex.ts
│   │   │   ├── trae.ts
│   │   │   ├── kiro.ts
│   │   │   └── antigravity.ts
│   │   ├── agent-detection.ts   # Find installed CLI tools
│   │   ├── agent-config.ts      # Generate config files
│   │   ├── shell-profile.ts     # Modify .zshrc/.bashrc
│   │   └── proxy-manager.ts     # Start/stop CLIProxyAPI binary
│   ├── models/
│   │   ├── provider.ts          # AIProvider enum
│   │   ├── agent.ts             # CLIAgent enum
│   │   ├── quota.ts             # ProviderQuota, ModelQuota
│   │   ├── auth.ts              # AuthFile, OAuth responses
│   │   └── config.ts            # AppConfig, RoutingConfig
│   ├── ipc/
│   │   ├── server.ts            # Unix socket server
│   │   ├── client.ts            # Client for GUI
│   │   └── protocol.ts          # Message types
│   └── utils/
│       ├── paths.ts             # Platform-specific paths
│       ├── logger.ts            # Structured logging
│       └── format.ts            # Table/JSON output
├── tests/
│   ├── services/
│   ├── commands/
│   └── fixtures/
├── scripts/
│   ├── build.ts                 # Build for all platforms
│   └── release.ts               # Package and publish
├── package.json
├── tsconfig.json
├── bunfig.toml
└── README.md
```

### 5.4 IPC Protocol

GUI wrappers communicate with `quotio-cli daemon` via JSON-RPC over Unix sockets.

```typescript
// IPC Message Types
interface IPCRequest {
  jsonrpc: "2.0";
  id: number;
  method: string;
  params?: Record<string, unknown>;
}

interface IPCResponse {
  jsonrpc: "2.0";
  id: number;
  result?: unknown;
  error?: { code: number; message: string };
}

// Example Methods
type Methods = {
  "quota.fetch": { provider?: string; forceRefresh?: boolean };
  "quota.list": {};
  "agent.detect": { forceRefresh?: boolean };
  "agent.configure": { agent: string; mode: "auto" | "manual" };
  "proxy.start": {};
  "proxy.stop": {};
  "proxy.status": {};
  "auth.list": {};
  "config.get": { key: string };
  "config.set": { key: string; value: unknown };
};
```

Socket paths:
- **macOS/Linux**: `~/.quotio/quotio.sock`
- **Windows**: `\\.\pipe\quotio`

---

## 6. Data Models

### 6.1 Provider Enum

```typescript
// src/models/provider.ts

export enum AIProvider {
  GEMINI = "gemini-cli",
  CLAUDE = "claude",
  CODEX = "codex",
  QWEN = "qwen",
  IFLOW = "iflow",
  ANTIGRAVITY = "antigravity",
  VERTEX = "vertex",
  KIRO = "kiro",
  COPILOT = "github-copilot",
  CURSOR = "cursor",
  TRAE = "trae",
  GLM = "glm",
}

export interface ProviderMetadata {
  id: AIProvider;
  displayName: string;
  color: string; // Hex color for UI
  oauthEndpoint: string | null;
  supportsQuotaOnlyMode: boolean;
  usesBrowserAuth: boolean;
  usesCLIQuota: boolean;
  supportsManualAuth: boolean;
  isQuotaTrackingOnly: boolean;
}

export const PROVIDER_METADATA: Record<AIProvider, ProviderMetadata> = {
  [AIProvider.GEMINI]: {
    id: AIProvider.GEMINI,
    displayName: "Gemini CLI",
    color: "#4285F4",
    oauthEndpoint: "/gemini-cli-auth-url",
    supportsQuotaOnlyMode: true,
    usesBrowserAuth: false,
    usesCLIQuota: true,
    supportsManualAuth: true,
    isQuotaTrackingOnly: false,
  },
  [AIProvider.CLAUDE]: {
    id: AIProvider.CLAUDE,
    displayName: "Claude Code",
    color: "#D97706",
    oauthEndpoint: "/anthropic-auth-url",
    supportsQuotaOnlyMode: true,
    usesBrowserAuth: false,
    usesCLIQuota: true,
    supportsManualAuth: true,
    isQuotaTrackingOnly: false,
  },
  // ... other providers
};
```

### 6.2 CLI Agent Enum

```typescript
// src/models/agent.ts

export enum CLIAgent {
  CLAUDE_CODE = "claude-code",
  CODEX_CLI = "codex",
  GEMINI_CLI = "gemini-cli",
  AMP_CLI = "amp",
  OPENCODE = "opencode",
  FACTORY_DROID = "factory-droid",
}

export enum AgentConfigType {
  ENVIRONMENT = "env",
  FILE = "file",
  BOTH = "both",
}

export interface AgentMetadata {
  id: CLIAgent;
  displayName: string;
  description: string;
  binaryNames: string[];
  configPaths: string[];
  configType: AgentConfigType;
  docsUrl: string | null;
}

export const AGENT_METADATA: Record<CLIAgent, AgentMetadata> = {
  [CLIAgent.CLAUDE_CODE]: {
    id: CLIAgent.CLAUDE_CODE,
    displayName: "Claude Code",
    description: "Anthropic's official CLI for Claude models",
    binaryNames: ["claude"],
    configPaths: ["~/.claude/settings.json"],
    configType: AgentConfigType.BOTH,
    docsUrl: "https://docs.anthropic.com/en/docs/claude-code",
  },
  [CLIAgent.CODEX_CLI]: {
    id: CLIAgent.CODEX_CLI,
    displayName: "Codex CLI",
    description: "OpenAI's Codex CLI for GPT-5 models",
    binaryNames: ["codex"],
    configPaths: ["~/.codex/config.toml", "~/.codex/auth.json"],
    configType: AgentConfigType.FILE,
    docsUrl: "https://github.com/openai/codex",
  },
  // ... other agents
};
```

### 6.3 Auth & Quota Types

```typescript
// src/models/auth.ts

export interface AuthFile {
  id: string;
  name: string;
  provider: string;
  label?: string;
  status: "ready" | "cooling" | "error";
  status_message?: string;
  disabled: boolean;
  unavailable: boolean;
  runtime_only?: boolean;
  source?: string;
  path?: string;
  email?: string;
  account_type?: string;
  account?: string;
  auth_index?: string;
  created_at?: string;
  updated_at?: string;
  last_refresh?: string;
}

// src/models/quota.ts

export interface ModelQuota {
  name: string;
  percentage: number; // 0-100 remaining
  resetTime: string; // ISO8601
  used?: number;
  limit?: number;
  remaining?: number;
}

export interface ProviderQuotaData {
  models: ModelQuota[];
  lastUpdated: Date;
  isForbidden: boolean;
  planType?: string;
}

export type QuotaMap = Record<string, ProviderQuotaData>; // email -> quota
```

### 6.4 Configuration

```typescript
// src/models/config.ts

export interface QuotioConfig {
  // CLIProxyAPI connection
  proxy: {
    host: string;
    port: number;
    authDir: string;
    autoStart: boolean;
  };
  
  // Quota settings
  quota: {
    refreshInterval: number; // seconds
    cacheTimeout: number; // seconds
    enabledProviders: AIProvider[];
  };
  
  // Output preferences
  output: {
    format: "table" | "json" | "plain";
    colors: boolean;
    verbose: boolean;
  };
  
  // IPC daemon
  daemon: {
    socketPath: string;
    autoStart: boolean;
  };
}

// Default config location: ~/.config/quotio-cli/config.toml
```

---

## 7. CLI Command Specification

### 7.1 Command Overview

```
quotio-cli <command> [subcommand] [options]

Commands:
  quota       Manage quota information
  agent       Manage CLI agent configuration
  proxy       Control CLIProxyAPI proxy
  auth        Manage authentication
  config      Manage configuration
  daemon      Run IPC daemon for GUI integration
  version     Show version information
```

### 7.2 Quota Commands

```bash
# Fetch quotas for all providers
quotio-cli quota fetch [--provider <name>] [--force] [--format json|table]

# List cached quotas
quotio-cli quota list [--format json|table]

# Watch quotas in real-time
quotio-cli quota watch [--interval <seconds>]

# Examples:
quotio-cli quota fetch                     # Fetch all
quotio-cli quota fetch --provider claude   # Fetch Claude only
quotio-cli quota fetch --format json       # JSON output for scripting
quotio-cli quota list                      # Show cached data
quotio-cli quota watch --interval 60       # Update every 60s
```

**Output Format (Table):**
```
┌──────────────┬─────────────────────┬───────────┬───────────┬─────────────────────┐
│ Provider     │ Account             │ Model     │ Remaining │ Resets At           │
├──────────────┼─────────────────────┼───────────┼───────────┼─────────────────────┤
│ Claude Code  │ user@example.com    │ 5-hour    │ 72%       │ 2026-01-12T23:00:00 │
│              │                     │ 7-day     │ 45%       │ 2026-01-15T00:00:00 │
│ Cursor       │ user@example.com    │ plan      │ 234/500   │ 2026-01-31T00:00:00 │
│ Copilot      │ github-user         │ premium   │ ∞         │ -                   │
└──────────────┴─────────────────────┴───────────┴───────────┴─────────────────────┘
```

**Output Format (JSON):**
```json
{
  "claude": {
    "user@example.com": {
      "models": [
        { "name": "five-hour-session", "percentage": 72, "resetTime": "2026-01-12T23:00:00Z" },
        { "name": "seven-day-weekly", "percentage": 45, "resetTime": "2026-01-15T00:00:00Z" }
      ],
      "lastUpdated": "2026-01-12T21:30:00Z",
      "isForbidden": false
    }
  }
}
```

### 7.3 Agent Commands

```bash
# Detect installed agents
quotio-cli agent detect [--force]

# List agent status
quotio-cli agent list [--format json|table]

# Configure an agent
quotio-cli agent configure <agent-name> [--mode auto|manual] [--model <model>]

# Test agent connection
quotio-cli agent test <agent-name>

# Show agent config
quotio-cli agent show <agent-name>

# Examples:
quotio-cli agent detect                            # Scan for installed agents
quotio-cli agent list                              # Show status
quotio-cli agent configure claude-code --mode auto # Auto-configure Claude
quotio-cli agent configure opencode --model gemini-claude-sonnet-4-5
quotio-cli agent test claude-code                  # Test connection
```

**Output (agent list):**
```
┌───────────────┬───────────┬────────────┬─────────────────────────────┬───────────┐
│ Agent         │ Installed │ Configured │ Binary Path                 │ Version   │
├───────────────┼───────────┼────────────┼─────────────────────────────┼───────────┤
│ Claude Code   │ ✓         │ ✓          │ ~/.bun/bin/claude           │ 1.2.3     │
│ Codex CLI     │ ✓         │ ✗          │ /usr/local/bin/codex        │ 0.9.1     │
│ Gemini CLI    │ ✓         │ ✓          │ ~/.bun/bin/gemini           │ 0.2.5     │
│ OpenCode      │ ✗         │ -          │ -                           │ -         │
└───────────────┴───────────┴────────────┴─────────────────────────────┴───────────┘
```

### 7.4 Proxy Commands

```bash
# Start proxy
quotio-cli proxy start [--port <port>] [--foreground]

# Stop proxy
quotio-cli proxy stop

# Show proxy status
quotio-cli proxy status [--format json|table]

# Restart proxy
quotio-cli proxy restart

# Show proxy logs
quotio-cli proxy logs [--follow] [--lines <n>]

# Examples:
quotio-cli proxy start                    # Start in background
quotio-cli proxy start --foreground       # Start in foreground
quotio-cli proxy status                   # Show running status
quotio-cli proxy logs --follow            # Tail logs
```

### 7.5 Auth Commands

```bash
# List authenticated accounts
quotio-cli auth list [--provider <name>] [--format json|table]

# Start OAuth flow
quotio-cli auth login <provider>

# Remove authentication
quotio-cli auth logout <provider> [--email <email>]

# Import credentials file
quotio-cli auth import <file>

# Export credentials (for backup)
quotio-cli auth export [--output <file>]

# Examples:
quotio-cli auth list                      # List all accounts
quotio-cli auth login claude              # Start Claude OAuth
quotio-cli auth logout claude --email user@example.com
quotio-cli auth import ~/vertex-sa.json   # Import Vertex service account
```

### 7.6 Config Commands

```bash
# Get config value
quotio-cli config get <key>

# Set config value
quotio-cli config set <key> <value>

# List all config
quotio-cli config list

# Reset to defaults
quotio-cli config reset [--key <key>]

# Edit config in editor
quotio-cli config edit

# Examples:
quotio-cli config get proxy.port                  # Get port
quotio-cli config set proxy.port 8318             # Set port
quotio-cli config set output.format json          # Set output format
quotio-cli config list                            # Show all
```

### 7.7 Daemon Commands

```bash
# Start IPC daemon
quotio-cli daemon start [--foreground]

# Stop IPC daemon
quotio-cli daemon stop

# Check daemon status
quotio-cli daemon status

# Examples:
quotio-cli daemon start                   # Start for GUI integration
quotio-cli daemon status                  # Check if running
```

### 7.8 Global Options

```bash
--help, -h          Show help
--version, -v       Show version
--verbose           Enable verbose output
--quiet, -q         Suppress non-essential output
--format <format>   Output format: table, json, plain (default: table)
--no-color          Disable colored output
--config <path>     Use custom config file
```

---

## 8. Implementation Phases

### Phase 1: Foundation (Week 1-2)

**Objective:** Project setup, core models, basic CLI skeleton

| Task | Priority | Estimated |
|------|----------|-----------|
| Initialize Bun project with TypeScript | P0 | 2h |
| Set up project structure | P0 | 2h |
| Port AIProvider enum + metadata | P0 | 4h |
| Port CLIAgent enum + metadata | P0 | 4h |
| Port AuthFile, ProviderQuotaData types | P0 | 4h |
| Implement ManagementAPIClient | P0 | 8h |
| Basic CLI router with Bunli | P0 | 4h |
| Config file loading (TOML) | P1 | 4h |
| Logging utility | P1 | 2h |
| Cross-platform path utilities | P1 | 4h |

**Deliverable:** `quotio-cli version` and `quotio-cli config list` working

### Phase 2: Quota Fetchers (Week 3-4)

**Objective:** Port all quota fetchers, enable `quota` commands

| Task | Priority | Estimated |
|------|----------|-----------|
| Port ClaudeCodeQuotaFetcher | P0 | 8h |
| Port CursorQuotaFetcher (SQLite) | P0 | 8h |
| Port CopilotQuotaFetcher | P0 | 6h |
| Port GeminiCLIQuotaFetcher | P0 | 4h |
| Port CodexCLIQuotaFetcher | P0 | 4h |
| Port TraeQuotaFetcher (SQLite) | P1 | 6h |
| Port KiroQuotaFetcher | P1 | 4h |
| Port AntigravityQuotaFetcher | P1 | 8h |
| Implement `quota fetch` command | P0 | 4h |
| Implement `quota list` command | P0 | 2h |
| Implement `quota watch` command | P1 | 4h |
| Table output formatter | P0 | 4h |
| JSON output formatter | P0 | 2h |

**Deliverable:** `quotio-cli quota fetch` returns all quotas

### Phase 3: Agent Services (Week 5-6)

**Objective:** Port agent detection and configuration

| Task | Priority | Estimated |
|------|----------|-----------|
| Port AgentDetectionService | P0 | 8h |
| Port AgentConfigurationService | P0 | 12h |
| Port ShellProfileManager | P0 | 4h |
| Implement `agent detect` command | P0 | 2h |
| Implement `agent list` command | P0 | 2h |
| Implement `agent configure` command | P0 | 8h |
| Implement `agent test` command | P1 | 4h |
| Config file merge logic (preserve user config) | P0 | 6h |
| Backup creation logic | P0 | 2h |

**Deliverable:** `quotio-cli agent configure claude-code --mode auto` works

### Phase 4: Proxy Management (Week 7)

**Objective:** Start/stop CLIProxyAPI, auth commands

| Task | Priority | Estimated |
|------|----------|-----------|
| Port ProxyManager (binary download, process management) | P0 | 12h |
| Implement `proxy start` command | P0 | 4h |
| Implement `proxy stop` command | P0 | 2h |
| Implement `proxy status` command | P0 | 2h |
| Implement `proxy logs` command | P1 | 4h |
| Implement `auth list` command | P0 | 2h |
| Implement `auth login` command | P0 | 4h |
| Implement `auth logout` command | P1 | 2h |
| Implement `auth import` command | P1 | 4h |

**Deliverable:** Full proxy lifecycle management via CLI

### Phase 5: IPC & Daemon (Week 8)

**Objective:** Enable GUI integration via IPC

| Task | Priority | Estimated |
|------|----------|-----------|
| Design JSON-RPC protocol | P0 | 4h |
| Implement Unix socket server | P0 | 8h |
| Implement Windows named pipe server | P1 | 8h |
| Implement `daemon start` command | P0 | 4h |
| Implement `daemon stop` command | P0 | 2h |
| IPC client library (for Swift) | P0 | 8h |
| Event streaming (quota updates, logs) | P1 | 8h |

**Deliverable:** GUI can communicate via `quotio-cli daemon`

### Phase 6: Build & Release (Week 9)

**Objective:** Cross-platform builds, packaging

| Task | Priority | Estimated |
|------|----------|-----------|
| Build script for all platforms | P0 | 4h |
| macOS ARM64 + x64 builds | P0 | 2h |
| Linux ARM64 + x64 builds | P0 | 2h |
| Windows x64 build | P0 | 2h |
| GitHub Actions CI/CD | P0 | 8h |
| Homebrew formula | P1 | 4h |
| npm publish (optional) | P2 | 4h |
| Release documentation | P0 | 4h |

**Deliverable:** Downloadable binaries for all platforms

### Phase 7: macOS App Integration (Week 10)

**Objective:** Migrate Swift app to use quotio-cli

| Task | Priority | Estimated |
|------|----------|-----------|
| Add IPC client to Swift app | P0 | 8h |
| Replace ManagementAPIClient calls | P0 | 8h |
| Replace QuotaFetcher calls | P0 | 8h |
| Replace AgentService calls | P0 | 8h |
| Test all features end-to-end | P0 | 8h |
| Performance optimization | P1 | 8h |
| Documentation update | P1 | 4h |

**Deliverable:** Quotio macOS app uses quotio-cli as backend

---

## 9. Migration Guide

### 9.1 Swift → TypeScript Migration Map

| Swift Component | TypeScript Target | Notes |
|-----------------|-------------------|-------|
| `AIProvider` enum | `src/models/provider.ts` | Remove Color, keep metadata |
| `CLIAgent` enum | `src/models/agent.ts` | Direct port |
| `AuthFile` struct | `src/models/auth.ts` | snake_case keys |
| `ManagementAPIClient` | `src/services/management-api.ts` | Use native fetch |
| `ClaudeCodeQuotaFetcher` | `src/services/quota-fetchers/claude.ts` | Port OAuth API calls |
| `CursorQuotaFetcher` | `src/services/quota-fetchers/cursor.ts` | Use bun:sqlite |
| `AgentDetectionService` | `src/services/agent-detection.ts` | Port which + path search |
| `AgentConfigurationService` | `src/services/agent-config.ts` | Port config generators |
| `ShellProfileManager` | `src/services/shell-profile.ts` | Direct port |

### 9.2 Key Differences

| Aspect | Swift | TypeScript |
|--------|-------|------------|
| **Concurrency** | `actor`, `async/await` | `async/await`, no actors needed |
| **JSON Parsing** | `Codable` with `CodingKeys` | Native JSON, Zod for validation |
| **File I/O** | `FileManager` | `Bun.file()`, `fs` |
| **Process Spawn** | `Process` | `Bun.spawn()` |
| **HTTP** | `URLSession` | Native `fetch` |
| **SQLite** | `SQLite3` via C | `bun:sqlite` |
| **Date** | `Date`, `ISO8601DateFormatter` | `Date`, `date-fns` |

### 9.3 Code Examples

**Swift (Original):**
```swift
actor ClaudeCodeQuotaFetcher {
    private let usageURL = "https://api.anthropic.com/api/oauth/usage"
    
    func fetchUsageFromAPI(accessToken: String) async -> ClaudeAPIResult {
        var request = URLRequest(url: URL(string: usageURL)!)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        // ...
    }
}
```

**TypeScript (Port):**
```typescript
// src/services/quota-fetchers/claude.ts

const USAGE_URL = "https://api.anthropic.com/api/oauth/usage";

export async function fetchClaudeUsage(accessToken: string): Promise<ClaudeQuotaResult> {
  const response = await fetch(USAGE_URL, {
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Accept": "application/json",
      "anthropic-beta": "oauth-2025-04-20",
    },
  });
  
  if (response.status === 401) {
    return { type: "auth_error" };
  }
  
  if (!response.ok) {
    return { type: "other_error" };
  }
  
  const data = await response.json();
  return { type: "success", data: parseClaudeUsage(data) };
}
```

---

## 10. Testing Strategy

### 10.1 Test Categories

| Category | Coverage Target | Tools |
|----------|-----------------|-------|
| Unit Tests | 80%+ | Bun test |
| Integration Tests | Core flows | Bun test + fixtures |
| E2E Tests | Critical paths | Shell scripts |
| Performance Tests | Startup, quota fetch | Benchmarks |

### 10.2 Unit Test Examples

```typescript
// tests/services/quota-fetchers/claude.test.ts

import { describe, test, expect, mock } from "bun:test";
import { fetchClaudeUsage, parseClaudeUsage } from "@/services/quota-fetchers/claude";

describe("ClaudeQuotaFetcher", () => {
  test("parses usage response correctly", () => {
    const response = {
      five_hour: { utilization: 28, resets_at: "2026-01-12T23:00:00Z" },
      seven_day: { utilization: 55, resets_at: "2026-01-15T00:00:00Z" },
    };
    
    const result = parseClaudeUsage(response);
    
    expect(result.fiveHour?.remaining).toBe(72);
    expect(result.sevenDay?.remaining).toBe(45);
  });
  
  test("handles authentication error", async () => {
    global.fetch = mock(() => Promise.resolve({ status: 401, ok: false }));
    
    const result = await fetchClaudeUsage("invalid-token");
    
    expect(result.type).toBe("auth_error");
  });
});
```

### 10.3 Integration Test Examples

```typescript
// tests/commands/quota.test.ts

import { describe, test, expect, beforeAll, afterAll } from "bun:test";
import { spawn } from "bun";

describe("quota commands", () => {
  test("quota fetch returns valid JSON", async () => {
    const proc = spawn(["./dist/quotio-cli", "quota", "fetch", "--format", "json"]);
    const output = await new Response(proc.stdout).text();
    const data = JSON.parse(output);
    
    expect(data).toHaveProperty("claude");
    expect(Array.isArray(data.claude)).toBe(true);
  });
});
```

### 10.4 E2E Test Script

```bash
#!/bin/bash
# tests/e2e/smoke.sh

set -e

echo "Testing quotio-cli E2E..."

# Version
./dist/quotio-cli version | grep -q "quotio-cli"

# Config
./dist/quotio-cli config list | grep -q "proxy.port"

# Quota (with fixture)
./dist/quotio-cli quota fetch --format json > /tmp/quota.json
jq -e '.claude' /tmp/quota.json

# Agent detect
./dist/quotio-cli agent list --format json > /tmp/agents.json
jq -e '.[0].id' /tmp/agents.json

echo "All E2E tests passed!"
```

---

## 11. Risk Assessment

### 11.1 Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Bun SQLite compatibility issues | Medium | High | Test on all platforms early; fallback to better-sqlite3 |
| Cross-platform path differences | Medium | Medium | Abstract path logic; extensive testing |
| IPC performance on Windows | Low | Medium | Use named pipes; benchmark |
| Binary size too large | Medium | Low | Tree-shaking; Bun compile optimizations |
| OAuth flow differences | Low | High | Keep OAuth in CLIProxyAPI |

### 11.2 Product Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Feature parity gaps | Medium | High | Comprehensive test matrix |
| User confusion (CLI vs GUI) | Medium | Medium | Clear documentation |
| Breaking changes for existing users | Low | High | Gradual migration; fallback support |

### 11.3 Mitigation Plan

1. **Early Platform Testing**: Set up CI for all platforms in Phase 1
2. **Feature Flags**: Enable gradual rollout of CLI backend in macOS app
3. **Compatibility Mode**: Support both direct API calls and CLI backend during transition
4. **User Communication**: Clear changelog and migration guide

---

## 12. Success Metrics

### 12.1 Technical Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Startup Time** | < 100ms | `time quotio-cli version` |
| **Quota Fetch Time** | < 2s (all providers) | Benchmark script |
| **Binary Size** | < 30MB | File size check |
| **Memory Usage** | < 50MB (daemon) | Process monitoring |
| **Test Coverage** | > 80% | Bun test coverage |

### 12.2 Product Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Platform Coverage** | 3 (macOS, Linux, Windows) | Release artifacts |
| **Feature Parity** | 100% | Feature checklist |
| **User Adoption** | 50% using CLI within 3 months | Analytics |
| **Bug Reports** | < 5 critical bugs in first month | Issue tracker |

---

## 13. Appendix

### 13.1 Glossary

| Term | Definition |
|------|------------|
| **CLIProxyAPI** | The Go-based proxy server that routes requests to AI providers |
| **quotio-cli** | The new TypeScript/Bun CLI being built in this project |
| **Quotio** | The macOS GUI application (existing) |
| **IPC** | Inter-Process Communication (Unix sockets / named pipes) |
| **Quota** | Usage limits tracked by AI providers (requests, tokens, etc.) |

### 13.2 References

- [Bun Documentation](https://bun.sh/docs)
- [Bun Compile](https://bun.sh/docs/bundler/executables)
- [Bunli CLI Framework](https://github.com/nicholasgriffintn/bunli)
- [CLIProxyAPI Repository](https://github.com/nguyenphutrong/cliproxyapi)
- [Quotio Repository](https://github.com/nguyenphutrong/quotio)

### 13.3 File Format References

**Claude Code settings.json:**
```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:8317",
    "ANTHROPIC_AUTH_TOKEN": "sk-xxx",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "gemini-claude-opus-4-5-thinking",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "gemini-claude-sonnet-4-5",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "gemini-3-flash-preview"
  },
  "model": "gemini-claude-opus-4-5-thinking",
  "permissions": { ... },
  "mcpServers": { ... }
}
```

**Codex CLI config.toml:**
```toml
model_provider = "cliproxyapi"
model = "gpt-5-codex"

[model_providers.cliproxyapi]
name = "cliproxyapi"
base_url = "http://localhost:8317/v1"
wire_api = "responses"
```

**OpenCode opencode.json:**
```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "quotio": {
      "name": "Quotio",
      "npm": "@ai-sdk/anthropic",
      "options": {
        "apiKey": "sk-xxx",
        "baseURL": "http://localhost:8317/v1"
      },
      "models": {
        "gemini-claude-sonnet-4-5": {
          "name": "Gemini Claude Sonnet 4.5",
          "limit": { "context": 200000, "output": 64000 }
        }
      }
    }
  }
}
```

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-01-12 | Quotio Team | Initial draft |

---

**End of Document**
