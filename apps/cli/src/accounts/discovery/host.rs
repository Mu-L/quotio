//! Host-owned native discovery and registration. Background inspection never grants OS access.
use super::{Registry, Request};
use crate::{
    accounts::{AccountError, api, service, vault::Vault},
    cli::Provider,
};
use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};
use time::OffsetDateTime;

#[derive(Clone, Debug, Deserialize, Serialize, PartialEq, Eq)]
pub struct Permission {
    pub provider: Provider,
    pub kind: String,
    pub location: Option<String>,
}
#[derive(Clone, Debug, Serialize)]
pub struct Failure {
    pub provider: Provider,
    pub kind: String,
    pub code: &'static str,
}
#[derive(Clone, Debug, Serialize)]
pub struct Scan {
    pub provider: Provider,
    #[serde(with = "time::serde::rfc3339")]
    pub at: OffsetDateTime,
}
#[derive(Clone, Debug, Serialize)]
pub struct Report {
    pub schema_version: u32,
    pub scans: Vec<Scan>,
    pub permissions: Vec<Permission>,
    pub known_sources: Vec<Permission>,
    pub failures: Vec<Failure>,
    pub registered: usize,
}
impl Default for Report {
    fn default() -> Self {
        Self {
            schema_version: 2,
            scans: Vec::new(),
            permissions: Vec::new(),
            known_sources: Vec::new(),
            failures: Vec::new(),
            registered: 0,
        }
    }
}

pub async fn scan(
    vault: Vault,
    registry: Arc<Mutex<Registry>>,
    providers: &[Provider],
    now: OffsetDateTime,
) -> Result<Report, AccountError> {
    // Check the host's own store before inspecting any provider credential sources.
    service::list(vault.clone()).await?;
    let mut report = Report::default();
    for &provider in providers {
        report.scans.push(Scan { provider, at: now });
        for source in crate::providers::capabilities::capability(provider).source_references {
            if source.origin != "borrowed_native"
                || source.kind == "quotio_custom_provider"
                || !source.platforms.contains(&std::env::consts::OS)
            {
                continue;
            }
            let inspect = registry.clone();
            let request = Request {
                provider,
                kind: source.kind.into(),
                location: None,
                domain: None,
                inspect: true,
            };
            let scanned = tokio::time::timeout(
                std::time::Duration::from_secs(10),
                tokio::task::spawn_blocking(move || {
                    inspect
                        .try_lock()
                        .map_err(|_| AccountError::Busy)?
                        .inspect(request)
                }),
            )
            .await;
            let value = match scanned {
                Ok(Ok(Ok(value))) => value,
                _ => {
                    report.failures.push(Failure {
                        provider,
                        kind: source.kind.into(),
                        code: "source_inspection_unavailable",
                    });
                    continue;
                }
            };
            if matches!(value["status"].as_str(), Some("unreadable" | "unsupported")) {
                report.failures.push(Failure {
                    provider,
                    kind: source.kind.into(),
                    code: "source_inspection_unavailable",
                });
            }
            for candidate in value["candidates"].as_array().into_iter().flatten() {
                let input = &candidate["source"];
                if candidate["status"] == "permission_required" {
                    let permission = Permission {
                        provider,
                        kind: input["kind"].as_str().unwrap_or(source.kind).into(),
                        location: input["location"].as_str().map(str::to_owned),
                    };
                    if !report.permissions.contains(&permission) {
                        report.permissions.push(permission);
                    }
                    continue;
                }
                if candidate["status"] != "available" {
                    continue;
                }
                let prepared = async {
                    let input: api::SourceInput =
                        serde_json::from_value(input.clone()).map_err(|_| AccountError::Input)?;
                    match input {
                        api::SourceInput::Discovered { discovery_ref } => {
                            let reference = registry
                                .try_lock()
                                .map_err(|_| AccountError::Busy)?
                                .get(&discovery_ref)?;
                            reference.resolve().await
                        }
                        input => api::prepare_source(input).await,
                    }
                };
                let result = match tokio::time::timeout(
                    std::time::Duration::from_secs(20),
                    prepared,
                )
                .await
                {
                    Ok(Ok(prepared)) => api::register_native(vault.clone(), prepared).await,
                    Ok(Err(error)) => Err(error),
                    Err(_) => Err(AccountError::Busy),
                };
                match result {
                    Ok(true) => report.registered += 1,
                    Ok(false) => (),
                    Err(_) => report.failures.push(Failure {
                        provider,
                        kind: source.kind.into(),
                        code: "source_registration_failed",
                    }),
                }
            }
        }
    }
    report.apply_registered(&service::list(vault).await?, providers);
    Ok(report)
}

impl Report {
    fn apply_registered(&mut self, accounts: &[crate::accounts::Account], providers: &[Provider]) {
        for account in accounts {
            if !providers.contains(&account.provider) {
                continue;
            }
            let metadata = api::AccountDto::from(account);
            if let Some(kind) = metadata.source_kind {
                let permission = Permission {
                    provider: account.provider,
                    kind: kind.into(),
                    location: metadata.source_location,
                };
                if !self.known_sources.contains(&permission) {
                    self.known_sources.push(permission);
                }
            }
        }
        self.permissions
            .retain(|permission| !self.known_sources.contains(permission));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::accounts::{random_string, vault::tests::Memory};

    #[test]
    fn a_registered_file_does_not_hide_another_keychain_location() {
        use crate::accounts::{
            Credential, Document,
            sources::{ClaudeLocation, ClaudeNativeReference},
        };
        let provider = Provider::Catalog("claude");
        let mut document = Document::default();
        document
            .add(
                provider,
                "File",
                "file".into(),
                Credential::ClaudeNative {
                    source: ClaudeNativeReference {
                        location: ClaudeLocation::CodeFile,
                        path: None,
                    },
                },
            )
            .unwrap();
        let permission = Permission {
            provider,
            kind: "claude_native".into(),
            location: Some("code_keychain".into()),
        };
        let mut report = Report {
            permissions: vec![permission.clone()],
            ..Report::default()
        };
        report.apply_registered(&document.accounts, &[provider]);
        assert_eq!(report.permissions, vec![permission]);
        let id = document
            .add(
                provider,
                "Keychain",
                "keychain".into(),
                Credential::ClaudeNative {
                    source: ClaudeNativeReference {
                        location: ClaudeLocation::CodeKeychain,
                        path: None,
                    },
                },
            )
            .unwrap();
        document.patch(&id, None, None, Some(false)).unwrap();
        report.apply_registered(&document.accounts, &[provider]);
        assert!(report.permissions.is_empty());
        assert_eq!(report.known_sources.len(), 2);
    }

    #[tokio::test]
    async fn scans_register_once_without_reenabling_sources_or_growing_receipts() {
        let dir = std::env::temp_dir().join(random_string().unwrap());
        std::fs::create_dir(&dir).unwrap();
        let home = dir.canonicalize().unwrap();
        let file = home.join(".config/github-copilot/apps.json");
        std::fs::create_dir_all(file.parent().unwrap()).unwrap();
        let original = br#"{"github.com":{"oauth_token":"native-discovery-secret"}}"#;
        std::fs::write(&file, original).unwrap();
        let registry = Arc::new(Mutex::new(Registry {
            home: Some(home.clone()),
            ..Registry::default()
        }));
        let vault = Vault::new(Arc::new(Memory::default()), home.join("vault.lock"));
        let providers = [Provider::Catalog("copilot")];
        let first = scan(
            vault.clone(),
            registry.clone(),
            &providers,
            OffsetDateTime::UNIX_EPOCH,
        )
        .await
        .unwrap();
        assert_eq!(first.registered, 1);
        assert!(first.permissions.is_empty());
        assert!(first.failures.is_empty());
        assert!(
            !serde_json::to_string(&first)
                .unwrap()
                .contains("native-discovery-secret")
        );
        let mut tx = vault.begin().unwrap();
        let id = tx.document.accounts[0].id.clone();
        tx.document.patch(&id, None, None, Some(false)).unwrap();
        tx.commit().unwrap();
        let before = serde_json::to_vec(&vault.begin().unwrap().document).unwrap();
        let second = scan(
            vault.clone(),
            registry,
            &providers,
            OffsetDateTime::UNIX_EPOCH,
        )
        .await
        .unwrap();
        assert_eq!(second.registered, 0);
        let tx = vault.begin().unwrap();
        assert!(!tx.document.accounts[0].enabled());
        assert!(tx.document.mutation_receipts.is_empty());
        assert_eq!(serde_json::to_vec(&tx.document).unwrap(), before);
        assert_eq!(std::fs::read(&file).unwrap(), original);
        drop(tx);
        std::fs::remove_dir_all(home).unwrap();
    }
}
