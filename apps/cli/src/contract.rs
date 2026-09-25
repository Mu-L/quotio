//! Version 2 transport types. These contain public metadata only, never credentials.
//! v1 serializers remain separate while clients migrate to the resolved host model.
use crate::domain::{AccountOrigin, Consumption, Provenance, Quota, QuotaAmounts};
use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use time::OffsetDateTime;
pub mod snapshot;

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Availability {
    pub available: bool,
    pub reason: Option<String>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Host {
    pub id: String,
    pub platform: String,
    pub api_versions: Vec<u32>,
    pub capabilities: BTreeMap<String, Availability>,
}

#[derive(Clone, Copy, Debug, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum IdentityEvidence {
    Unknown,
    Local,
    Verified,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Identity {
    pub evidence: IdentityEvidence,
    pub username: Option<String>,
    pub email: Option<String>,
}

#[derive(Clone, Copy, Debug, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum ConnectionState {
    Ready,
    NotChecked,
    NeedsAuthorization,
    NeedsLogin,
    Unavailable,
    Disabled,
}

#[derive(Clone, Copy, Debug, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum InteractionLocation {
    Client,
    Host,
    HostUser,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Action {
    pub kind: String,
    pub available: bool,
    pub reason: Option<String>,
    pub interaction: InteractionLocation,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Issue {
    pub code: String,
    pub retryable: bool,
    pub action: Option<Action>,
}

#[derive(Clone, Copy, Debug, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum RefreshOwner {
    Host,
    ProviderTool,
    None,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Source {
    pub id: String,
    pub origin: AccountOrigin,
    pub kind: String,
    /// Semantic location code, not a filesystem path or Keychain secret.
    pub location: Option<String>,
    pub enabled: bool,
    pub selected: bool,
    pub state: ConnectionState,
    pub refresh_owner: RefreshOwner,
    pub issue: Option<Issue>,
    pub actions: Vec<Action>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Account {
    pub id: String,
    pub provider_id: String,
    /// Final backend-selected name. Clients must not apply provider-specific precedence.
    pub display_name: String,
    pub user_label: Option<String>,
    pub identity: Identity,
    pub enabled: bool,
    pub active: bool,
    pub state: ConnectionState,
    pub sources: Vec<Source>,
    pub actions: Vec<Action>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Metric {
    pub id: String,
    pub display_name: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
    pub quota: Quota,
    pub amounts: Option<QuotaAmounts>,
    pub consumption: Option<Consumption>,
    #[serde(with = "time::serde::rfc3339::option")]
    pub resets_at: Option<OffsetDateTime>,
    pub reset_description: Option<String>,
    #[serde(with = "time::serde::rfc3339")]
    pub fetched_at: OffsetDateTime,
    pub provenance: Provenance,
}

#[derive(Clone, Copy, Debug, Deserialize, Serialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum Freshness {
    NotLoaded,
    Fresh,
    Stale,
    Unavailable,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Usage {
    pub account_id: String,
    pub freshness: Freshness,
    #[serde(with = "time::serde::rfc3339::option")]
    pub fetched_at: Option<OffsetDateTime>,
    #[serde(with = "time::serde::rfc3339::option")]
    pub expires_at: Option<OffsetDateTime>,
    pub plan: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub subscription_status: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub reset_credits: Option<crate::domain::ResetCredits>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub antigravity_subscription: Option<crate::domain::AntigravitySubscriptionInfo>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub codex_profile: Option<crate::domain::CodexProfileAnalytics>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub codex_reset_credits: Option<crate::domain::CodexResetCreditInventory>,
    pub metrics: Vec<Metric>,
    pub issue: Option<Issue>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct AccountList {
    pub schema_version: u32,
    pub host: Host,
    pub revision: u64,
    pub accounts: Vec<Account>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Snapshot {
    pub schema_version: u32,
    pub host: Host,
    /// Persisted host revision. A lower revision never supersedes a newer client snapshot.
    pub revision: u64,
    #[serde(with = "time::serde::rfc3339")]
    pub generated_at: OffsetDateTime,
    pub accounts: Vec<Account>,
    pub usage: Vec<Usage>,
}

impl Snapshot {
    /// Check cross-resource invariants before publishing or accepting a snapshot.
    /// Schema checks separately enforce field types and required properties.
    pub fn validate(&self) -> Result<(), &'static str> {
        use std::collections::HashSet;
        if self.schema_version != 2
            || self.host.id.is_empty()
            || !self.host.api_versions.contains(&2)
        {
            return Err("incompatible_contract");
        }
        let mut accounts = HashSet::new();
        let mut sources = HashSet::new();
        for account in &self.accounts {
            if account.id.is_empty()
                || !accounts.insert(&account.id)
                || account.provider_id.is_empty()
                || account.display_name.trim().is_empty()
                || account
                    .sources
                    .iter()
                    .filter(|source| source.selected)
                    .count()
                    > 1
            {
                return Err("invalid_account");
            }
            for source in &account.sources {
                if source.id.is_empty()
                    || !sources.insert(&source.id)
                    || (source.selected && (!source.enabled || !account.enabled))
                {
                    return Err("invalid_source");
                }
            }
        }
        let mut usages = HashSet::new();
        for usage in &self.usage {
            if !accounts.contains(&usage.account_id) || !usages.insert(&usage.account_id) {
                return Err("invalid_usage_account");
            }
            let mut metrics = HashSet::new();
            for metric in &usage.metrics {
                if metric.id.is_empty() || !metrics.insert(&metric.id) || !metric.quota.is_valid() {
                    return Err("invalid_metric");
                }
            }
        }
        Ok(())
    }
}
