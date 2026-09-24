use super::{
    AccountError,
    api::SourceInput,
    sources::{AntigravityLocation, ClaudeLocation, CopilotLocation, FactoryLocation},
};

pub(crate) fn target(
    input: &SourceInput,
) -> Result<(&'static str, Option<&'static str>), AccountError> {
    match input {
        SourceInput::CopilotNative {
            location: CopilotLocation::GhKeychain,
            entry_key,
        } if entry_key.is_empty() || entry_key == "github.com" => Ok(("gh:github.com", None)),
        SourceInput::ClaudeNative {
            location: ClaudeLocation::CodeKeychain,
        } => Ok(("Claude Code-credentials", None)),
        SourceInput::AntigravityNative {
            location: AntigravityLocation::GeminiKeychain,
        } => Ok(("gemini", Some("antigravity"))),
        SourceInput::FactoryNative {
            location:
                FactoryLocation::V2LoginKeychain | FactoryLocation::V2Keyring | FactoryLocation::Legacy,
        } => Ok(("Factory CLI", None)),
        _ => Err(AccountError::Input),
    }
}

pub(crate) async fn authorize(input: SourceInput) -> Result<SourceInput, AccountError> {
    let (service, account) = target(&input)?;
    let mut account = if service == "gh:github.com" {
        crate::providers::catalog::oauth_primary::copilot_keychain_account().await?
    } else {
        account.map(str::to_owned)
    };
    tokio::task::spawn_blocking(move || {
        use crate::providers::catalog::common;
        if service == "Factory CLI"
            && common::keychain_item_exists(service, Some("auth-encryption-key-security-cli"))?
        {
            account = Some("auth-encryption-key-security-cli".into());
        }
        common::authorize_keychain(service, account.as_deref())
    })
    .await
    .map_err(|_| AccountError::Storage)??;
    Ok(input)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn authorization_only_accepts_supported_keychain_sources() {
        for (kind, location) in [
            ("claude_native", "code_keychain"),
            ("copilot_native", "gh_keychain"),
            ("factory_native", "v2_keyring"),
            ("antigravity_native", "gemini_keychain"),
        ] {
            let source: SourceInput =
                serde_json::from_value(serde_json::json!({"kind":kind,"location":location}))
                    .unwrap();
            assert!(target(&source).is_ok());
        }
        for source in [
            SourceInput::ClaudeNative {
                location: ClaudeLocation::CodeFile,
            },
            SourceInput::FactoryNative {
                location: FactoryLocation::V2File,
            },
            SourceInput::AmpNative {},
        ] {
            assert!(target(&source).is_err());
        }
        assert!(serde_json::from_value::<SourceInput>(serde_json::json!({"kind":"claude_native","location":"code_keychain","service":"arbitrary"})).is_err());
    }
}
