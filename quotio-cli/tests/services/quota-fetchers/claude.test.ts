import { describe, test, expect, mock, afterEach, beforeEach } from "bun:test";
import { ClaudeQuotaFetcher } from "../../../src/services/quota-fetchers/claude.ts";
import { AIProvider } from "../../../src/models/provider.ts";
import * as fixtures from "../../fixtures/claude-usage.ts";

const originalFetch = globalThis.fetch;

describe("ClaudeQuotaFetcher", () => {
  let fetcher: ClaudeQuotaFetcher;

  beforeEach(() => {
    fetcher = new ClaudeQuotaFetcher();
  });

  afterEach(() => {
    globalThis.fetch = originalFetch;
  });

  test("provider is AIProvider.CLAUDE", () => {
    expect(fetcher.provider).toBe(AIProvider.CLAUDE);
  });

  describe("fetchForAccount", () => {
    test("parses successful usage response with five_hour and seven_day", async () => {
      globalThis.fetch = mock(async () => {
        return new Response(JSON.stringify(fixtures.claudeUsageSuccess), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("user@example.com", "valid-token");

      expect(result.account).toBe("user@example.com");
      expect(result.provider).toBe(AIProvider.CLAUDE);
      expect(result.error).toBeUndefined();
      expect(result.data).toBeDefined();
      expect(result.data?.isForbidden).toBe(false);

      const models = result.data?.models ?? [];
      expect(models.length).toBe(2);

      const fiveHour = models.find((m) => m.name === "five-hour-session");
      expect(fiveHour).toBeDefined();
      expect(fiveHour?.percentage).toBe(72);
      expect(fiveHour?.resetTime).toBe("2026-01-13T23:00:00Z");

      const sevenDay = models.find((m) => m.name === "seven-day-weekly");
      expect(sevenDay).toBeDefined();
      expect(sevenDay?.percentage).toBe(45);
    });

    test("parses response with sonnet and opus quotas", async () => {
      globalThis.fetch = mock(async () => {
        return new Response(JSON.stringify(fixtures.claudeUsageWithSonnetOpus), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("user@example.com", "valid-token");

      const models = result.data?.models ?? [];
      expect(models.length).toBe(4);

      const sonnet = models.find((m) => m.name === "seven-day-sonnet");
      expect(sonnet?.percentage).toBe(70);

      const opus = models.find((m) => m.name === "seven-day-opus");
      expect(opus?.percentage).toBe(60);
    });

    test("parses response with extra_usage credits", async () => {
      globalThis.fetch = mock(async () => {
        return new Response(JSON.stringify(fixtures.claudeUsageWithExtraUsage), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("user@example.com", "valid-token");

      const models = result.data?.models ?? [];
      const extraUsage = models.find((m) => m.name === "extra-usage");

      expect(extraUsage).toBeDefined();
      expect(extraUsage?.percentage).toBe(75);
      expect(extraUsage?.used).toBe(125);
      expect(extraUsage?.limit).toBe(500);
    });

    test("handles 401 authentication error", async () => {
      globalThis.fetch = mock(async () => {
        return new Response("Unauthorized", { status: 401 });
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("user@example.com", "invalid-token");

      expect(result.error).toBeUndefined();
      expect(result.data?.isForbidden).toBe(true);
    });

    test("handles API authentication_error in response body", async () => {
      globalThis.fetch = mock(async () => {
        return new Response(JSON.stringify(fixtures.claudeUsageAuthError), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("user@example.com", "expired-token");

      expect(result.data?.isForbidden).toBe(true);
    });

    test("handles generic API error in response body", async () => {
      globalThis.fetch = mock(async () => {
        return new Response(JSON.stringify(fixtures.claudeUsageGenericError), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("user@example.com", "valid-token");

      expect(result.error).toBe("Rate limit exceeded");
    });

    test("handles network error", async () => {
      globalThis.fetch = mock(async () => {
        throw new Error("Network timeout");
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("user@example.com", "valid-token");

      expect(result.error).toBe("Network timeout");
    });

    test("handles empty usage response", async () => {
      globalThis.fetch = mock(async () => {
        return new Response(JSON.stringify(fixtures.claudeUsageEmpty), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      }) as unknown as typeof fetch;

      const result = await fetcher.fetchForAccount("user@example.com", "valid-token");

      expect(result.data?.models.length).toBe(0);
      expect(result.data?.isForbidden).toBe(false);
    });
  });
});
