import { AIProvider } from "../../models/provider.ts";
import type { QuotaFetcher, QuotaFetchResult, ProviderQuotaData, ModelQuota } from "./types.ts";
import { readAuthFiles, fetchWithTimeout, getAuthDir } from "./types.ts";

const USAGE_ENDPOINT = "https://codewhisperer.us-east-1.amazonaws.com/getUsageLimits";
const TOKEN_ENDPOINT = "https://oidc.us-east-1.amazonaws.com/token";

interface KiroUsageBreakdown {
  displayName?: string;
  resourceType?: string;
  currentUsage?: number;
  currentUsageWithPrecision?: number;
  usageLimit?: number;
  usageLimitWithPrecision?: number;
  nextDateReset?: number;
  freeTrialInfo?: {
    currentUsage?: number;
    currentUsageWithPrecision?: number;
    usageLimit?: number;
    usageLimitWithPrecision?: number;
    freeTrialStatus?: string;
    freeTrialExpiry?: number;
  };
}

interface KiroUsageResponse {
  usageBreakdownList?: KiroUsageBreakdown[];
  subscriptionInfo?: {
    subscriptionTitle?: string;
    type?: string;
  };
  userInfo?: {
    email?: string;
    userId?: string;
  };
  nextDateReset?: number;
}

interface KiroTokenResponse {
  access_token: string;
  expires_in: number;
  token_type: string;
  refresh_token?: string;
}

function isTokenExpired(expiresAt?: string): boolean {
  if (!expiresAt) return false;

  const expiryDate = new Date(expiresAt);
  return expiryDate < new Date();
}

async function refreshToken(
  refreshToken: string,
  clientId: string,
  clientSecret: string
): Promise<KiroTokenResponse | null> {
  try {
    const authString = `${clientId}:${clientSecret}`;
    const base64Auth = Buffer.from(authString).toString("base64");

    const bodyParams = new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: refreshToken,
      client_id: clientId,
    });

    const response = await fetchWithTimeout({
      url: TOKEN_ENDPOINT,
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: `Basic ${base64Auth}`,
      },
      body: bodyParams.toString(),
    });

    if (!response.ok) {
      return null;
    }

    return (await response.json()) as KiroTokenResponse;
  } catch {
    return null;
  }
}

async function persistRefreshedToken(
  filePath: string,
  newAccessToken: string,
  newRefreshToken: string | undefined,
  expiresIn: number
): Promise<void> {
  try {
    const file = Bun.file(filePath);
    const json = await file.json();

    json.access_token = newAccessToken;
    if (newRefreshToken) {
      json.refresh_token = newRefreshToken;
    }

    const newExpiresAt = new Date(Date.now() + expiresIn * 1000);
    json.expires_at = newExpiresAt.toISOString();
    json.last_refresh = new Date().toISOString();

    await Bun.write(filePath, JSON.stringify(json, null, 2));
  } catch {
    // Silent failure - token refresh still succeeded in memory
  }
}

async function fetchUsage(accessToken: string): Promise<KiroUsageResponse | null> {
  try {
    const response = await fetchWithTimeout({
      url: `${USAGE_ENDPOINT}?isEmailRequired=true&origin=AI_EDITOR`,
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "User-Agent": "aws-sdk-js/3.0.0 KiroIDE-0.1.0 os/macos lang/js md/nodejs/18.0.0",
        "x-amz-user-agent": "aws-sdk-js/3.0.0",
      },
    });

    if (!response.ok) {
      return null;
    }

    return (await response.json()) as KiroUsageResponse;
  } catch {
    return null;
  }
}

function formatResetTimeFromTimestamp(timestamp?: number): string {
  if (!timestamp) return "";
  const date = new Date(timestamp * 1000);
  return date.toISOString();
}

function convertToProviderQuota(response: KiroUsageResponse): ProviderQuotaData {
  const models: ModelQuota[] = [];
  const nextReset = response.nextDateReset;
  const resetTimeStr = formatResetTimeFromTimestamp(nextReset);

  if (response.usageBreakdownList) {
    for (const breakdown of response.usageBreakdownList) {
      const displayName = breakdown.displayName ?? breakdown.resourceType ?? "Usage";
      const hasActiveTrial = breakdown.freeTrialInfo?.freeTrialStatus === "ACTIVE";

      if (hasActiveTrial && breakdown.freeTrialInfo) {
        const freeTrialInfo = breakdown.freeTrialInfo;
        const used = freeTrialInfo.currentUsageWithPrecision ?? freeTrialInfo.currentUsage ?? 0;
        const total = freeTrialInfo.usageLimitWithPrecision ?? freeTrialInfo.usageLimit ?? 0;

        let percentage = 0;
        if (total > 0) {
          percentage = Math.max(0, ((total - used) / total) * 100);
        }

        let trialResetStr = resetTimeStr;
        if (freeTrialInfo.freeTrialExpiry) {
          trialResetStr = formatResetTimeFromTimestamp(freeTrialInfo.freeTrialExpiry);
        }

        models.push({
          name: `Bonus ${displayName}`,
          percentage,
          resetTime: trialResetStr,
        });
      }

      const regularUsed = breakdown.currentUsageWithPrecision ?? breakdown.currentUsage ?? 0;
      const regularTotal = breakdown.usageLimitWithPrecision ?? breakdown.usageLimit ?? 0;

      if (regularTotal > 0) {
        const percentage = Math.max(0, ((regularTotal - regularUsed) / regularTotal) * 100);
        const quotaName = hasActiveTrial ? `${displayName} (Base)` : displayName;

        models.push({
          name: quotaName,
          percentage,
          resetTime: resetTimeStr,
        });
      }
    }
  }

  if (models.length === 0) {
    models.push({
      name: "kiro-standard",
      percentage: 100,
      resetTime: "",
    });
  }

  return {
    models,
    lastUpdated: new Date(),
    isForbidden: false,
    planType: response.subscriptionInfo?.subscriptionTitle ?? "Standard",
  };
}

export class KiroQuotaFetcher implements QuotaFetcher {
  readonly provider = AIProvider.KIRO;

  async fetchAll(): Promise<QuotaFetchResult[]> {
    const authFiles = await readAuthFiles("kiro-");
    if (authFiles.length === 0) return [];

    const results: QuotaFetchResult[] = [];

    for (const authFile of authFiles) {
      if (!authFile.accessToken) continue;

      let currentToken = authFile.accessToken;

      if (isTokenExpired(authFile.expiresAt?.toString()) && authFile.refreshToken) {
        const fileContent = await this.readFullAuthFile(authFile.path);
        if (fileContent?.client_id && fileContent?.client_secret) {
          const refreshed = await refreshToken(
            authFile.refreshToken,
            fileContent.client_id,
            fileContent.client_secret
          );

          if (refreshed) {
            currentToken = refreshed.access_token;
            await persistRefreshedToken(
              authFile.path,
              refreshed.access_token,
              refreshed.refresh_token,
              refreshed.expires_in
            );
          }
        }
      }

      const usageResponse = await fetchUsage(currentToken);

      if (!usageResponse) {
        results.push({
          account: authFile.email ?? authFile.account ?? "Kiro User",
          provider: this.provider,
          error: "Failed to fetch usage data",
        });
        continue;
      }

      const quotaData = convertToProviderQuota(usageResponse);
      const accountKey = authFile.name.replace(/\.json$/, "").replace(/^kiro-/, "");

      results.push({
        account: accountKey,
        provider: this.provider,
        data: quotaData,
      });
    }

    return results;
  }

  async fetchForAccount(
    account: string,
    accessToken: string
  ): Promise<QuotaFetchResult> {
    const usageResponse = await fetchUsage(accessToken);

    if (!usageResponse) {
      return {
        account,
        provider: this.provider,
        error: "Failed to fetch usage data",
      };
    }

    const quotaData = convertToProviderQuota(usageResponse);

    return {
      account,
      provider: this.provider,
      data: quotaData,
    };
  }

  private async readFullAuthFile(
    filePath: string
  ): Promise<{ client_id?: string; client_secret?: string } | null> {
    try {
      const file = Bun.file(filePath);
      return await file.json();
    } catch {
      return null;
    }
  }
}
