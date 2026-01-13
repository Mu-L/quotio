export const claudeUsageSuccess = {
  five_hour: {
    utilization: 28,
    resets_at: "2026-01-13T23:00:00Z",
  },
  seven_day: {
    utilization: 55,
    resets_at: "2026-01-15T00:00:00Z",
  },
};

export const claudeUsageWithSonnetOpus = {
  five_hour: {
    utilization: 10,
    resets_at: "2026-01-13T23:00:00Z",
  },
  seven_day: {
    utilization: 20,
    resets_at: "2026-01-15T00:00:00Z",
  },
  seven_day_sonnet: {
    utilization: 30,
    resets_at: "2026-01-15T00:00:00Z",
  },
  seven_day_opus: {
    utilization: 40,
    resets_at: "2026-01-15T00:00:00Z",
  },
};

export const claudeUsageWithExtraUsage = {
  five_hour: {
    utilization: 50,
    resets_at: "2026-01-13T23:00:00Z",
  },
  seven_day: {
    utilization: 60,
    resets_at: "2026-01-15T00:00:00Z",
  },
  extra_usage: {
    is_enabled: true,
    monthly_limit: 500,
    used_credits: 125.5,
    utilization: 25,
  },
};

export const claudeUsageAuthError = {
  type: "error",
  error: {
    type: "authentication_error",
    message: "Invalid or expired token",
  },
};

export const claudeUsageGenericError = {
  type: "error",
  error: {
    type: "rate_limit_error",
    message: "Rate limit exceeded",
  },
};

export const claudeUsageEmpty = {};
