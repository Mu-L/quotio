/**
 * Platform-specific paths for quotio-cli configuration and data storage.
 * Follows XDG Base Directory Specification on Linux, standard paths on macOS/Windows.
 */

import { homedir } from "node:os";
import { join } from "node:path";

/** Detected operating system */
export type Platform = "darwin" | "linux" | "win32";

/** Get current platform */
export function getPlatform(): Platform {
  const platform = process.platform;
  if (platform === "darwin" || platform === "linux" || platform === "win32") {
    return platform;
  }
  // Default to linux for other Unix-like systems
  return "linux";
}

/**
 * Get the base configuration directory for quotio-cli.
 * - macOS: ~/Library/Application Support/quotio-cli
 * - Linux: ~/.config/quotio-cli (XDG_CONFIG_HOME)
 * - Windows: %APPDATA%/quotio-cli
 */
export function getConfigDir(): string {
  const platform = getPlatform();
  const home = homedir();

  switch (platform) {
    case "darwin":
      return join(home, "Library", "Application Support", "quotio-cli");
    case "win32":
      return join(process.env.APPDATA || join(home, "AppData", "Roaming"), "quotio-cli");
    case "linux":
    default:
      return join(process.env.XDG_CONFIG_HOME || join(home, ".config"), "quotio-cli");
  }
}

/**
 * Get the data directory for quotio-cli (logs, cache, etc.).
 * - macOS: ~/Library/Application Support/quotio-cli
 * - Linux: ~/.local/share/quotio-cli (XDG_DATA_HOME)
 * - Windows: %LOCALAPPDATA%/quotio-cli
 */
export function getDataDir(): string {
  const platform = getPlatform();
  const home = homedir();

  switch (platform) {
    case "darwin":
      return join(home, "Library", "Application Support", "quotio-cli");
    case "win32":
      return join(process.env.LOCALAPPDATA || join(home, "AppData", "Local"), "quotio-cli");
    case "linux":
    default:
      return join(process.env.XDG_DATA_HOME || join(home, ".local", "share"), "quotio-cli");
  }
}

/**
 * Get the cache directory for quotio-cli.
 * - macOS: ~/Library/Caches/quotio-cli
 * - Linux: ~/.cache/quotio-cli (XDG_CACHE_HOME)
 * - Windows: %LOCALAPPDATA%/quotio-cli/cache
 */
export function getCacheDir(): string {
  const platform = getPlatform();
  const home = homedir();

  switch (platform) {
    case "darwin":
      return join(home, "Library", "Caches", "quotio-cli");
    case "win32":
      return join(process.env.LOCALAPPDATA || join(home, "AppData", "Local"), "quotio-cli", "cache");
    case "linux":
    default:
      return join(process.env.XDG_CACHE_HOME || join(home, ".cache"), "quotio-cli");
  }
}

/**
 * Get the logs directory for quotio-cli.
 * - macOS: ~/Library/Logs/quotio-cli
 * - Linux: ~/.local/share/quotio-cli/logs
 * - Windows: %LOCALAPPDATA%/quotio-cli/logs
 */
export function getLogsDir(): string {
  const platform = getPlatform();
  const home = homedir();

  switch (platform) {
    case "darwin":
      return join(home, "Library", "Logs", "quotio-cli");
    case "win32":
      return join(process.env.LOCALAPPDATA || join(home, "AppData", "Local"), "quotio-cli", "logs");
    case "linux":
    default:
      return join(getDataDir(), "logs");
  }
}

/** Standard file paths within the config directory */
export const ConfigFiles = {
  /** Main configuration file */
  config: () => join(getConfigDir(), "config.json"),
  /** Credentials/auth tokens */
  credentials: () => join(getConfigDir(), "credentials.json"),
  /** CLI state (last used settings, etc.) */
  state: () => join(getDataDir(), "state.json"),
  /** Daemon socket/pipe path */
  socket: () => {
    const platform = getPlatform();
    if (platform === "win32") {
      return "\\\\.\\pipe\\quotio-cli";
    }
    return join(getCacheDir(), "quotio.sock");
  },
  /** PID file for daemon */
  pidFile: () => join(getCacheDir(), "quotio.pid"),
} as const;

/**
 * Ensure a directory exists, creating it if necessary.
 */
export async function ensureDir(dir: string): Promise<void> {
  const fs = await import("node:fs/promises");
  await fs.mkdir(dir, { recursive: true });
}

/**
 * Ensure all quotio-cli directories exist.
 */
export async function ensureAllDirs(): Promise<void> {
  await Promise.all([
    ensureDir(getConfigDir()),
    ensureDir(getDataDir()),
    ensureDir(getCacheDir()),
    ensureDir(getLogsDir()),
  ]);
}

/**
 * Get CLIProxyAPI default paths (where the Swift app stores data).
 * Used for migration and compatibility.
 */
export const CLIProxyPaths = {
  /** Default CLIProxyAPI base URL */
  defaultBaseURL: "http://localhost:8217",
  /** macOS app support directory for CLIProxyAPI */
  macOSAppSupport: () => join(homedir(), "Library", "Application Support", "CLIProxyAPI"),
  /** Auth files location */
  authFiles: () => join(homedir(), "Library", "Application Support", "CLIProxyAPI", "auth"),
} as const;
