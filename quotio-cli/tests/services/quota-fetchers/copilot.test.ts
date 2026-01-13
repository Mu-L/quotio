import { describe, test, expect, mock, afterEach, beforeEach } from "bun:test";
import { CopilotQuotaFetcher } from "../../../src/services/quota-fetchers/copilot.ts";
import { AIProvider } from "../../../src/models/provider.ts";
import * as fixtures from "../../fixtures/copilot-usage.ts";

const originalFetch = globalThis.fetch;

describe("CopilotQuotaFetcher", () => {
  let fetcher: CopilotQuotaFetcher;

  beforeEach(() => {
    fetcher = new CopilotQuotaFetcher();
  });

  afterEach(() => {
    globalThis.fetch = originalFetch;
  });

  test("provider is AIProvider.COPILOT", () => {
    expect(fetcher.provider).toBe(AIProvider.COPILOT);
  });

  describe("fetchForAccount", () => {
    test("parses quota_snapshots response", async () => {
      globalThis.fetch = mock(async () => {
        return new Response(JSON.stringify(fixtures.copilotQuotaSnapshots), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("github-user", "valid-token");

      expect(result.account).toBe("github-user");
      expect(result.provider).toBe(AIProvider.COPILOT);
      expect(result.error).toBeUndefined();
      expect(result.data).toBeDefined();
      expect(result.data?.isForbidden).toBe(false);
    });

    test("parses limited_user_quotas response", async () => {
      globalThis.fetch = mock(async () => {
        return new Response(JSON.stringify(fixtures.copilotLimitedQuotas), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("github-user", "valid-token");

      expect(result.data).toBeDefined();
      expect(result.error).toBeUndefined();
    });

    test("handles unlimited quotas", async () => {
      globalThis.fetch = mock(async () => {
        return new Response(JSON.stringify(fixtures.copilotUnlimitedQuotas), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("github-user", "valid-token");

      expect(result.data).toBeDefined();
      expect(result.data?.isForbidden).toBe(false);
    });

    test("handles mixed quotas (some unlimited, some limited)", async () => {
      globalThis.fetch = mock(async () => {
        return new Response(JSON.stringify(fixtures.copilotMixedQuotas), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("github-user", "valid-token");

      expect(result.data).toBeDefined();
    });

    test("handles 401 forbidden", async () => {
      globalThis.fetch = mock(async () => {
        return new Response("Unauthorized", { status: 401 });
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("github-user", "invalid-token");

      expect(result.data?.isForbidden).toBe(true);
    });

    test("handles 403 forbidden", async () => {
      globalThis.fetch = mock(async () => {
        return new Response("Forbidden", { status: 403 });
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("github-user", "invalid-token");

      expect(result.data?.isForbidden).toBe(true);
    });

    test("handles network error", async () => {
      globalThis.fetch = mock(async () => {
        throw new Error("Connection refused");
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("github-user", "valid-token");

      expect(result.error).toBe("Connection refused");
    });

    test("handles empty response", async () => {
      globalThis.fetch = mock(async () => {
        return new Response(JSON.stringify(fixtures.copilotEmptyResponse), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("github-user", "valid-token");

      expect(result.data).toBeDefined();
      expect(result.data?.models.length).toBe(0);
    });
  });
});
