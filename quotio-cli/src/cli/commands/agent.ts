import { parseArgs } from "node:util";
import { registerCommand, type CLIContext, type CommandResult } from "../index.ts";
import { logger, formatTable, colors, type TableColumn } from "../../utils/index.ts";
import {
  getAgentDetectionService,
  getAgentConfigurationService,
  ALL_CLI_AGENTS,
  type CLIAgentId,
  type AgentConfiguration,
} from "../../services/agent-detection/index.ts";

const agentColumns: TableColumn[] = [
  { key: "name", header: "Agent", width: 18 },
  { key: "status", header: "Status", width: 14 },
  { key: "version", header: "Version", width: 25 },
  { key: "path", header: "Path", width: 40 },
];

async function handleAgent(args: string[], ctx: CLIContext): Promise<CommandResult> {
  const { values, positionals } = parseArgs({
    args,
    options: {
      help: { type: "boolean", short: "h", default: false },
      agent: { type: "string", short: "a" },
      url: { type: "string", short: "u", default: "http://localhost:8217/v1" },
      key: { type: "string", short: "k", default: "quotio-api-key" },
      mode: { type: "string", short: "m", default: "manual" },
    },
    allowPositionals: true,
    strict: false,
  });

  const subcommand = positionals[0] ?? "list";

  if (values.help) {
    printAgentHelp();
    return { success: true };
  }

  switch (subcommand) {
    case "list":
    case "ls":
      return await listAgents(ctx);
    case "detect":
      return await detectAgents(ctx);
    case "configure":
    case "config":
      return await configureAgent(ctx, values as ConfigureOptions);
    default:
      logger.error(`Unknown agent subcommand: ${subcommand}`);
      printAgentHelp();
      return { success: false, message: `Unknown subcommand: ${subcommand}` };
  }
}

interface ConfigureOptions {
  agent?: string;
  url?: string;
  key?: string;
  mode?: string;
}

function printAgentHelp(): void {
  const help = `
quotio agent - CLI agent configuration

Usage: quotio agent <subcommand> [options]

Subcommands:
  list, ls           List supported agents
  detect             Detect installed agents
  configure, config  Generate configuration for an agent

Options:
  --help, -h         Show this help message
  --agent, -a        Agent to configure (required for configure)
  --url, -u          Proxy URL (default: http://localhost:8217/v1)
  --key, -k          API key (default: quotio-api-key)
  --mode, -m         Mode: automatic or manual (default: manual)

Agents:
  claude-code        Claude Code (Anthropic)
  codex              Codex CLI (OpenAI)
  gemini-cli         Gemini CLI (Google)
  amp                Amp CLI (Sourcegraph)
  opencode           OpenCode
  factory-droid      Factory Droid

Examples:
  quotio agent list
  quotio agent detect
  quotio agent configure --agent claude-code --mode manual
  quotio agent config -a opencode -u http://localhost:8217/v1 -k mykey
`.trim();

  logger.print(help);
}

async function listAgents(ctx: CLIContext): Promise<CommandResult> {
  const agents = ALL_CLI_AGENTS.map((agent) => ({
    id: agent.id,
    name: agent.displayName,
    description: agent.description,
    configType: agent.configType,
    binaryNames: agent.binaryNames,
  }));

  if (ctx.format === "json") {
    logger.print(JSON.stringify(agents, null, 2));
  } else {
    logger.print(colors.bold("Supported CLI Agents:\n"));
    for (const agent of agents) {
      logger.print(`  ${colors.cyan(agent.name)} ${colors.dim(`(${agent.id})`)}`);
      logger.print(`    ${colors.dim(agent.description)}`);
      logger.print(`    ${colors.dim(`Binaries: ${agent.binaryNames.join(", ")}`)}`);
      logger.print("");
    }
  }

  return { success: true, data: agents };
}

async function detectAgents(ctx: CLIContext): Promise<CommandResult> {
  const detectionService = getAgentDetectionService();
  const statuses = await detectionService.detectAllAgents();

  const results = statuses.map((status) => ({
    name: status.agent.displayName,
    status: formatStatus(status.installed, status.configured),
    version: status.version ?? "-",
    path: status.binaryPath ?? "-",
    configured: status.configured,
    installed: status.installed,
  }));

  if (ctx.format === "json") {
    logger.print(JSON.stringify(results, null, 2));
  } else {
    logger.print(colors.bold("Agent Detection Results:\n"));
    logger.print(formatTable(results, agentColumns));

    const installed = results.filter((r) => r.installed).length;
    const configured = results.filter((r) => r.configured).length;
    logger.print(
      `\n${colors.dim(`Found: ${installed}/${results.length} installed, ${configured} configured`)}`
    );
  }

  return { success: true, data: results };
}

function formatStatus(installed: boolean, configured: boolean): string {
  if (!installed) {
    return colors.dim("Not found");
  }
  if (configured) {
    return colors.green("Configured");
  }
  return colors.yellow("Installed");
}

async function configureAgent(ctx: CLIContext, options: ConfigureOptions): Promise<CommandResult> {
  if (!options.agent) {
    logger.error("Agent is required. Use --agent or -a to specify.");
    logger.print(`\nAvailable agents: ${ALL_CLI_AGENTS.map((a) => a.id).join(", ")}`);
    return { success: false, message: "Agent is required" };
  }

  const agentId = options.agent as CLIAgentId;
  const agent = ALL_CLI_AGENTS.find((a) => a.id === agentId);

  if (!agent) {
    logger.error(`Unknown agent: ${agentId}`);
    logger.print(`\nAvailable agents: ${ALL_CLI_AGENTS.map((a) => a.id).join(", ")}`);
    return { success: false, message: `Unknown agent: ${agentId}` };
  }

  const mode = options.mode === "automatic" ? "automatic" : "manual";
  const configService = getAgentConfigurationService();

  const config: AgentConfiguration = {
    agent,
    proxyURL: options.url ?? "http://localhost:8217/v1",
    apiKey: options.key ?? "quotio-api-key",
  };

  const result = configService.generateConfiguration(agentId, config, mode);

  if (ctx.format === "json") {
    logger.print(JSON.stringify(result, null, 2));
    return { success: result.success, data: result };
  }

  if (!result.success) {
    logger.error(`Configuration failed: ${result.error}`);
    return { success: false, message: result.error };
  }

  logger.print(colors.bold(`\n${agent.displayName} Configuration\n`));
  logger.print(colors.dim(`Mode: ${mode}`));
  logger.print(colors.dim(`Config type: ${result.configType}`));
  logger.print("");

  if (mode === "automatic") {
    logger.print(colors.green(result.instructions));
    if (result.configPath) {
      logger.print(`\n${colors.dim("Config path:")} ${result.configPath}`);
    }
    if (result.backupPath) {
      logger.print(`${colors.dim("Backup created:")} ${result.backupPath}`);
    }
  } else {
    logger.print(colors.yellow(result.instructions));
    logger.print("");

    for (const rawConfig of result.rawConfigs) {
      logger.print(colors.bold(`\n--- ${rawConfig.filename ?? rawConfig.format.toUpperCase()} ---`));
      if (rawConfig.targetPath) {
        logger.print(colors.dim(`Target: ${rawConfig.targetPath}`));
      }
      logger.print(colors.dim(rawConfig.instructions));
      logger.print("");
      logger.print(rawConfig.content);
      logger.print("");
    }
  }

  return { success: true, data: result };
}

registerCommand("agent", handleAgent);

export { handleAgent };
