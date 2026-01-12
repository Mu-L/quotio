import { parseArgs } from "node:util";
import { registerCommand, type CLIContext, type CommandResult } from "../index.ts";
import { ManagementAPIClient } from "../../services/management-api.ts";
import { logger, formatJson, colors } from "../../utils/index.ts";

async function handleConfig(args: string[], ctx: CLIContext): Promise<CommandResult> {
  const { values, positionals } = parseArgs({
    args,
    options: {
      help: { type: "boolean", short: "h", default: false },
    },
    allowPositionals: true,
    strict: false,
  });

  const subcommand = positionals[0] ?? "get";

  if (values.help) {
    printConfigHelp();
    return { success: true };
  }

  const client = new ManagementAPIClient({
    baseURL: ctx.baseUrl,
    authKey: "",
  });

  switch (subcommand) {
    case "get":
      return await getConfig(client, ctx, positionals.slice(1));
    case "set":
      return await setConfig(client, ctx, positionals.slice(1));
    default:
      logger.error(`Unknown config subcommand: ${subcommand}`);
      printConfigHelp();
      return { success: false, message: `Unknown subcommand: ${subcommand}` };
  }
}

function printConfigHelp(): void {
  const help = `
quotio config - Configuration management

Usage: quotio config <subcommand> [key] [value]

Subcommands:
  get [key]         Get configuration (all or specific key)
  set <key> <value> Set configuration value

Available keys:
  debug             Enable/disable debug mode (true/false)
  routing           Routing strategy (round-robin/fill-first)
  retry             Request retry count (number)
  max-retry-interval Maximum retry interval in seconds

Options:
  --help, -h    Show this help message

Examples:
  quotio config get
  quotio config get debug
  quotio config set debug true
  quotio config set routing round-robin
  quotio config set retry 3
`.trim();

  logger.print(help);
}

async function getConfig(client: ManagementAPIClient, ctx: CLIContext, args: string[]): Promise<CommandResult> {
  try {
    const key = args[0];

    if (!key) {
      const config = await client.fetchConfig();
      if (ctx.format === "json") {
        logger.print(formatJson(config));
      } else {
        logger.print(`debug: ${config.debug}`);
        logger.print(`routing: ${config.routing?.strategy ?? "round-robin"}`);
        logger.print(`retry: ${config.requestRetry ?? 0}`);
        logger.print(`max-retry-interval: ${config.maxRetryInterval ?? 0}s`);
        logger.print(`logging-to-file: ${config.loggingToFile ?? false}`);
      }
      return { success: true, data: config };
    }

    let value: unknown;
    switch (key) {
      case "debug":
        value = await client.getDebug();
        break;
      case "retry":
        value = await client.getRequestRetry();
        break;
      case "max-retry-interval":
        value = await client.getMaxRetryInterval();
        break;
      case "logging-to-file":
        value = await client.getLoggingToFile();
        break;
      case "proxy-url":
        value = await client.getProxyURL();
        break;
      default:
        return { success: false, message: `Unknown config key: ${key}` };
    }

    if (ctx.format === "json") {
      logger.print(formatJson({ [key]: value }));
    } else {
      logger.print(`${key}: ${value}`);
    }

    return { success: true, data: { [key]: value } };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return { success: false, message: `Failed to get config: ${message}` };
  }
}

async function setConfig(client: ManagementAPIClient, ctx: CLIContext, args: string[]): Promise<CommandResult> {
  const [key, value] = args;

  if (!key || value === undefined) {
    logger.error("Usage: quotio config set <key> <value>");
    return { success: false, message: "Key and value required" };
  }

  try {
    switch (key) {
      case "debug":
        await client.setDebug(value === "true" || value === "1");
        break;
      case "routing":
        if (value !== "round-robin" && value !== "fill-first") {
          return { success: false, message: "Routing must be 'round-robin' or 'fill-first'" };
        }
        await client.setRoutingStrategy(value);
        break;
      case "retry": {
        const retryCount = parseInt(value, 10);
        if (isNaN(retryCount) || retryCount < 0) {
          return { success: false, message: "Retry must be a non-negative number" };
        }
        await client.setRequestRetry(retryCount);
        break;
      }
      case "max-retry-interval": {
        const interval = parseInt(value, 10);
        if (isNaN(interval) || interval < 0) {
          return { success: false, message: "Max retry interval must be a non-negative number" };
        }
        await client.setMaxRetryInterval(interval);
        break;
      }
      case "logging-to-file":
        await client.setLoggingToFile(value === "true" || value === "1");
        break;
      case "proxy-url":
        if (value === "" || value === "null" || value === "none") {
          await client.deleteProxyURL();
        } else {
          await client.setProxyURL(value);
        }
        break;
      default:
        return { success: false, message: `Unknown config key: ${key}` };
    }

    logger.print(colors.green(`Set ${key} = ${value}`));
    return { success: true };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return { success: false, message: `Failed to set config: ${message}` };
  }
}

registerCommand("config", handleConfig);

export { handleConfig };
