export const cursorDbRow = {
  key: "aiService.billingData",
  value: JSON.stringify({
    user: {
      email: "user@example.com",
      name: "Test User",
    },
    subscription: {
      plan: "pro",
      status: "active",
    },
    usage: {
      numRequests: 150,
      numRequestsTotal: 500,
      numTokens: 50000,
      numTokensTotal: 200000,
      startOfCycleDate: "2026-01-01T00:00:00Z",
      endOfCycleDate: "2026-01-31T23:59:59Z",
    },
    premiumUsage: {
      numPremiumRequests: 50,
      maxPremiumRequests: 500,
    },
  }),
};

export const cursorDbRowBusiness = {
  key: "aiService.billingData",
  value: JSON.stringify({
    user: {
      email: "enterprise@company.com",
      name: "Enterprise User",
    },
    subscription: {
      plan: "business",
      status: "active",
    },
    usage: {
      numRequests: 1000,
      numRequestsTotal: 10000,
      numTokens: 500000,
      numTokensTotal: 2000000,
      startOfCycleDate: "2026-01-01T00:00:00Z",
      endOfCycleDate: "2026-01-31T23:59:59Z",
    },
    premiumUsage: {
      numPremiumRequests: 200,
      maxPremiumRequests: 2000,
    },
  }),
};

export const cursorDbRowFree = {
  key: "aiService.billingData",
  value: JSON.stringify({
    user: {
      email: "free@example.com",
      name: "Free User",
    },
    subscription: {
      plan: "free",
      status: "active",
    },
    usage: {
      numRequests: 45,
      numRequestsTotal: 50,
      numTokens: 10000,
      numTokensTotal: 15000,
      startOfCycleDate: "2026-01-01T00:00:00Z",
      endOfCycleDate: "2026-01-31T23:59:59Z",
    },
  }),
};

export const cursorDbRowNoUser = {
  key: "aiService.billingData",
  value: JSON.stringify({
    subscription: {
      plan: "pro",
      status: "active",
    },
  }),
};
