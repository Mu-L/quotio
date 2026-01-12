import { parseArgs } from "node:util";
import { registerCommand, type CLIContext, type CommandResult } from "../index.ts";
import { ManagementAPIClient } from "../../services/management-api.ts";
import { logger, formatJson, colors } from "../../utils/index.ts";

async function handleProxy(args: string[], ctx: CLIContext): Promise<CommandResult> {
  const { values, positionals } = parseArgs({
    args,
    options: {
      help: { type: "boolean", short: "h", default: false },
    },
    allowPositionals: true,
    strict: false,
  });

  const subcommand = positionals[0] ?? "status";

  if (values.help) {
    printProxyHelp();
    return { success: true };
  }

  const client = new ManagementAPIClient({
    baseURL: ctx.baseUrl,
    authKey: "",
  });

  switch (subcommand) {
    case "status":
      return await proxyStatus(client, ctx);
    case "health":
      return await healthCheck(client, ctx);
    default:
      logger.error(`Unknown proxy subcommand: ${subcommand}`);
      printProxyHelp();
      return { success: false, message: `Unknown subcommand: ${subcommand}` };
  }
}

function printProxyHelp(): void {
  const help = `
quotio proxy - Proxy server control

Usage: quotio proxy <subcommand> [options]

Subcommands:
  status        Show proxy status (default)
  health        Check if proxy is healthy

Options:
  --help, -h    Show this help message

Examples:
  quotio proxy
  quotio proxy status
  quotio proxy health
`.trim();

  logger.print(help);
}

async function proxyStatus(client: ManagementAPIClient, ctx: CLIContext): Promise<CommandResult> {
  try {
    const healthy = await client.healthCheck();
    const config = healthy ? await client.fetchConfig() : null;

    if (ctx.format === "json") {
      logger.print(formatJson({ healthy, config }));
    } else {
      if (healthy) {
        logger.print(`Status: ${colors.green("Running")}`);
        logger.print(`URL: ${ctx.baseUrl}`);
        if (config) {
        logger.print(`Debug: ${config.debug ? "enabled" : "disabled"}`);
        logger.print(`Routing: ${config.routing?.strategy ?? "round-robin"}`);
        }
      } else {
        logger.print(`Status: ${colors.red("Not running")}`);
        logger.print(`Expected URL: ${ctx.baseUrl}`);
      }
    }

    return { success: true, data: { healthy, config } };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return { success: false, message: `Failed to get proxy status: ${message}` };
  }
}

async function healthCheck(client: ManagementAPIClient, ctx: CLIContext): Promise<CommandResult> {
  try {
    const healthy = await client.healthCheck();

    if (ctx.format === "json") {
      logger.print(formatJson({ healthy }));
    } else {
      if (healthy) {
        logger.print(colors.green("Proxy is healthy"));
      } else {
        logger.print(colors.red("Proxy is not responding"));
      }
    }

    return { success: healthy, data: { healthy } };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return { success: false, message: `Health check failed: ${message}` };
  }
}

registerCommand("proxy", handleProxy);

export { handleProxy };
