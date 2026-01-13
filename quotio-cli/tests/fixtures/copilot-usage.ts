export const copilotQuotaSnapshots = {
  quota_snapshots: [
    {
      code_completions: {
        limit: 5000,
        remaining: 4500,
        reset_at: "2026-01-31T00:00:00Z",
      },
      chat_messages: {
        limit: 1000,
        remaining: 800,
        reset_at: "2026-01-31T00:00:00Z",
      },
    },
  ],
};

export const copilotLimitedQuotas = {
  limited_user_quotas: {
    chat: {
      unlimited: false,
      monthly_chat_messages_limit: 500,
      monthly_chat_messages_remaining: 350,
      premium_chat_messages_limit: 100,
      premium_chat_messages_remaining: 75,
    },
    completions: {
      unlimited: false,
      code_completions_limit: 2000,
      code_completions_remaining: 1500,
    },
  },
};

export const copilotUnlimitedQuotas = {
  limited_user_quotas: {
    chat: {
      unlimited: true,
    },
    completions: {
      unlimited: true,
    },
  },
};

export const copilotMixedQuotas = {
  limited_user_quotas: {
    chat: {
      unlimited: true,
    },
    completions: {
      unlimited: false,
      code_completions_limit: 2000,
      code_completions_remaining: 500,
    },
  },
};

export const copilotEmptyResponse = {};
