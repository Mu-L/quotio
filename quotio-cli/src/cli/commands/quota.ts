import { parseArgs } from "node:util";
import { registerCommand, type CLIContext, type CommandResult } from "../index.ts";
import { ManagementAPIClient } from "../../services/management-api.ts";
import { logger, formatTable, formatJson, colors, type TableColumn } from "../../utils/index.ts";
import { PROVIDER_METADATA, type AIProvider } from "../../models/index.ts";
import { isAuthReady } from "../../models/auth.ts";

const quotaColumns: TableColumn[] = [
  { key: "provider", header: "Provider", width: 15 },
  { key: "account", header: "Account", width: 25 },
  { key: "status", header: "Status", width: 10 },
];

async function handleQuota(args: string[], ctx: CLIContext): Promise<CommandResult> {
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
    printQuotaHelp();
    return { success: true };
  }

  const client = new ManagementAPIClient({
    baseURL: ctx.baseUrl,
    authKey: "",
  });

  switch (subcommand) {
    case "list":
    case "ls":
      return await listQuotas(client, ctx);
    case "fetch":
    case "refresh":
      return await fetchQuotas(client, ctx);
    default:
      logger.error(`Unknown quota subcommand: ${subcommand}`);
      printQuotaHelp();
      return { success: false, message: `Unknown subcommand: ${subcommand}` };
  }
}

function printQuotaHelp(): void {
  const help = `
quotio quota - Manage quota information

Usage: quotio quota <subcommand> [options]

Subcommands:
  list, ls      List all provider quotas (default)
  fetch         Fetch fresh quota data from providers

Options:
  --help, -h    Show this help message

Examples:
  quotio quota
  quotio quota list
  quotio quota fetch
`.trim();

  logger.print(help);
}

async function listQuotas(client: ManagementAPIClient, ctx: CLIContext): Promise<CommandResult> {
  try {
    const authFiles = await client.fetchAuthFiles();

    if (authFiles.length === 0) {
      logger.print(colors.dim("No authenticated providers found."));
      logger.print("\nRun 'quotio auth login <provider>' to authenticate.");
      return { success: true, data: [] };
    }

    const rows = authFiles.map((auth) => {
      const metadata = PROVIDER_METADATA[auth.provider as AIProvider];
      const displayName = metadata?.displayName ?? auth.provider;

      let statusDisplay: string;
      if (isAuthReady(auth)) {
        statusDisplay = colors.green("Active");
      } else if (auth.statusMessage?.includes("expired")) {
        statusDisplay = colors.yellow("Expired");
      } else if (auth.disabled) {
        statusDisplay = colors.dim("Disabled");
      } else {
        statusDisplay = colors.red("Invalid");
      }

      const accountDisplay = auth.email ?? auth.account ?? auth.label ?? "-";

      return {
        provider: displayName,
        account: accountDisplay,
        status: statusDisplay,
      };
    });

    if (ctx.format === "json") {
      logger.print(formatJson(authFiles));
    } else {
      logger.print(formatTable(rows, quotaColumns));
    }

    return { success: true, data: authFiles };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return { success: false, message: `Failed to list quotas: ${message}` };
  }
}

async function fetchQuotas(client: ManagementAPIClient, ctx: CLIContext): Promise<CommandResult> {
  try {
    logger.info("Fetching quota data from providers...");

    const stats = await client.fetchUsageStats();

    if (ctx.format === "json") {
      logger.print(formatJson(stats));
    } else {
      logger.print(colors.green("Quota data refreshed successfully."));
      if (stats.usage) {
        logger.print(colors.dim(`Total requests: ${stats.usage.totalRequests ?? 0}`));
      }
    }

    return { success: true, data: stats };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return { success: false, message: `Failed to fetch quotas: ${message}` };
  }
}

registerCommand("quota", handleQuota);

export { handleQuota };
