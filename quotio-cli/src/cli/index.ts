import { parseArgs } from "node:util";
import { logger, parseLogLevel, type OutputFormat } from "../utils/index.ts";

export interface CLIContext {
  format: OutputFormat;
  verbose: boolean;
  baseUrl: string;
}

export interface CommandResult {
  success: boolean;
  message?: string;
  data?: unknown;
}

type CommandHandler = (args: string[], ctx: CLIContext) => Promise<CommandResult>;

const commands: Map<string, CommandHandler> = new Map();

export function registerCommand(name: string, handler: CommandHandler): void {
  commands.set(name, handler);
}

function printHelp(): void {
  const help = `
quotio - CLI for managing CLIProxyAPI

Usage: quotio <command> [options]

Commands:
  quota    Manage quota information
  auth     Authentication management
  proxy    Proxy server control
  agent    CLI agent configuration
  config   Configuration management
  version  Show version information
  help     Show this help message

Global Options:
  --format <type>   Output format: table, json, plain (default: table)
  --verbose, -v     Enable verbose output
  --base-url <url>  CLIProxyAPI base URL (default: http://localhost:8217)
  --help, -h        Show help for a command

Examples:
  quotio quota list
  quotio auth login anthropic
  quotio proxy status
  quotio agent detect
  quotio config get
`.trim();

  logger.print(help);
}

function printVersion(): void {
  const pkg = require("../../package.json");
  logger.print(`quotio v${pkg.version}`);
}

export async function run(argv: string[] = process.argv): Promise<void> {
  const args = argv.slice(2);

  if (args.length === 0 || args[0] === "help" || args[0] === "--help" || args[0] === "-h") {
    printHelp();
    return;
  }

  if (args[0] === "version" || args[0] === "--version" || args[0] === "-V") {
    printVersion();
    return;
  }

  const { values, positionals } = parseArgs({
    args,
    options: {
      format: { type: "string", default: "table" },
      verbose: { type: "boolean", short: "v", default: false },
      "base-url": { type: "string", default: "http://localhost:8217" },
      help: { type: "boolean", short: "h", default: false },
    },
    allowPositionals: true,
    strict: false,
  });

  if (values.verbose) {
    logger.configure({ level: parseLogLevel("debug") });
  }

  const ctx: CLIContext = {
    format: (typeof values.format === "string" ? values.format : "table") as OutputFormat,
    verbose: typeof values.verbose === "boolean" ? values.verbose : false,
    baseUrl: typeof values["base-url"] === "string" ? values["base-url"] : "http://localhost:8217",
  };

  const [command, ...commandArgs] = positionals;

  if (!command) {
    printHelp();
    return;
  }

  if (values.help) {
    const handler = commands.get(command);
    if (handler) {
      await handler(["--help"], ctx);
    } else {
      printHelp();
    }
    return;
  }

  const handler = commands.get(command);
  if (!handler) {
    logger.error(`Unknown command: ${command}`);
    logger.print("\nRun 'quotio help' to see available commands.");
    process.exit(1);
  }

  try {
    const result = await handler(commandArgs, ctx);
    if (!result.success) {
      logger.error(result.message ?? "Command failed");
      process.exit(1);
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error(`Command failed: ${message}`);
    if (ctx.verbose && error instanceof Error && error.stack) {
      logger.debug(error.stack);
    }
    process.exit(1);
  }
}
