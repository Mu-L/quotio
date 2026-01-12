import { parseArgs } from "node:util";
import { registerCommand, type CLIContext, type CommandResult } from "../index.ts";
import { logger, formatTable, colors, type TableColumn } from "../../utils/index.ts";
import { CLIAgent, AGENT_METADATA } from "../../models/index.ts";

const agentColumns: TableColumn[] = [
  { key: "name", header: "Agent", width: 15 },
  { key: "status", header: "Status", width: 12 },
  { key: "path", header: "Path", width: 40 },
];

async function handleAgent(args: string[], ctx: CLIContext): Promise<CommandResult> {
  const { values, positionals } = parseArgs({
    args,
    options: {
      help: { type: "boolean", short: "h", default: false },
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
    default:
      logger.error(`Unknown agent subcommand: ${subcommand}`);
      printAgentHelp();
      return { success: false, message: `Unknown subcommand: ${subcommand}` };
  }
}

function printAgentHelp(): void {
  const help = `
quotio agent - CLI agent configuration

Usage: quotio agent <subcommand> [options]

Subcommands:
  list, ls      List supported agents
  detect        Detect installed agents

Options:
  --help, -h    Show this help message

Examples:
  quotio agent list
  quotio agent detect
`.trim();

  logger.print(help);
}

async function listAgents(ctx: CLIContext): Promise<CommandResult> {
  const agents = Object.values(CLIAgent).map((agent) => {
    const metadata = AGENT_METADATA[agent];
    return {
      id: agent,
      name: metadata.displayName,
      description: metadata.description,
      configType: metadata.configType,
    };
  });

  if (ctx.format === "json") {
    logger.print(JSON.stringify(agents, null, 2));
  } else {
    logger.print(colors.bold("Supported CLI Agents:\n"));
    for (const agent of agents) {
      logger.print(`  ${colors.cyan(agent.name)}`);
      logger.print(`    ${colors.dim(agent.description)}`);
      logger.print("");
    }
  }

  return { success: true, data: agents };
}

async function detectAgents(ctx: CLIContext): Promise<CommandResult> {
  const results: Array<{ name: string; status: string; path: string }> = [];

  for (const agent of Object.values(CLIAgent)) {
    const metadata = AGENT_METADATA[agent];
    const detected = await detectAgent(agent);

    results.push({
      name: metadata.displayName,
      status: detected.found ? colors.green("Found") : colors.dim("Not found"),
      path: detected.path ?? "-",
    });
  }

  if (ctx.format === "json") {
    logger.print(JSON.stringify(results, null, 2));
  } else {
    logger.print(formatTable(results, agentColumns));
  }

  return { success: true, data: results };
}

async function detectAgent(agent: CLIAgent): Promise<{ found: boolean; path?: string }> {
  const metadata = AGENT_METADATA[agent];
  const possiblePaths = getAgentPaths(agent, metadata);

  for (const path of possiblePaths) {
    try {
      const file = Bun.file(path);
      if (await file.exists()) {
        return { found: true, path };
      }
    } catch {
      continue;
    }
  }

  return { found: false };
}

function getAgentPaths(agent: CLIAgent, metadata: typeof AGENT_METADATA[CLIAgent]): string[] {
  const home = process.env.HOME ?? "";
  const basePaths = metadata.configPaths.map(p => p.replace(/^~/, home));
  
  switch (agent) {
    case CLIAgent.CLAUDE_CODE:
      return [...basePaths, `${home}/.config/claude/settings.json`];
    case CLIAgent.CODEX_CLI:
      return [...basePaths, `${home}/.config/codex/config.toml`];
    case CLIAgent.GEMINI_CLI:
      return [`${home}/.config/gcloud/application_default_credentials.json`];
    case CLIAgent.AMP_CLI:
      return [...basePaths, `${home}/.local/share/amp/secrets.json`];
    case CLIAgent.OPENCODE:
      return [...basePaths, `${home}/.config/opencode/config.json`];
    case CLIAgent.FACTORY_DROID:
      return [...basePaths, `${home}/.config/factory/config.json`];
    default:
      return basePaths;
  }
}

registerCommand("agent", handleAgent);

export { handleAgent };
