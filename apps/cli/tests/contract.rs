//! Offline conformance checks shared by CLI and HTTP serializers.
use clap::ValueEnum;
use quotio::{
    cli::Provider,
    domain::UsageReport,
    providers::{Clock, CredentialStore, ProviderContext, Secret, capabilities::ProviderList},
};
use serde_json::{Value, json};
use std::sync::Arc;
use time::{OffsetDateTime, macros::datetime};

fn validator(name: &str) -> jsonschema::Validator {
    let document: Value = serde_json::from_str(include_str!("../docs/openapi.json")).unwrap();
    jsonschema::draft202012::options()
        .should_validate_formats(true)
        .build(&json!({
            "$ref":format!("#/components/schemas/{name}"),
            "components": document["components"]
        }))
        .unwrap()
}

#[test]
fn every_registered_provider_conforms_to_the_public_contract() {
    let value = serde_json::to_value(ProviderList::new(&[Provider::Mock])).unwrap();
    validator("ProviderList").validate(&value).unwrap();
    let providers = value["providers"].as_array().unwrap();
    assert_eq!(providers.len(), Provider::value_variants().len());
    for provider in Provider::value_variants() {
        let rows: Vec<_> = providers
            .iter()
            .filter(|row| row["id"] == provider.id())
            .collect();
        assert_eq!(rows.len(), 1, "{}", provider.id());
        assert_eq!(rows[0]["id"], rows[0]["capabilities"]["provider"]);
        assert!(
            rows[0]["capabilities"]["operations"]
                .as_array()
                .unwrap()
                .contains(&json!("usage"))
        );
    }
    let mut invalid = value.clone();
    invalid["providers"][0]["enabled"] = json!("true");
    assert!(!validator("ProviderList").is_valid(&invalid));
}

struct Fixture;
impl Clock for Fixture {
    fn now(&self) -> OffsetDateTime {
        datetime!(2026-01-01 0:00 UTC)
    }
}
impl CredentialStore for Fixture {
    fn get(&self, _: &str) -> Option<Secret> {
        panic!("mock contract must not read credentials")
    }
}

#[tokio::test]
async fn mock_serializer_matches_the_shared_frontend_fixture() {
    let context = ProviderContext {
        http: reqwest::Client::new(),
        clock: Arc::new(Fixture),
        credentials: Arc::new(Fixture),
    };
    let report = UsageReport {
        schema_version: 1,
        generated_at: context.clock.now(),
        providers: vec![Provider::Mock.adapter().fetch(&context).await.unwrap()],
        failures: vec![],
    };
    let value = serde_json::to_value(&report).unwrap();
    let fixture: Value =
        serde_json::from_str(include_str!("fixtures/contracts/usage-v1.json")).unwrap();
    assert_eq!(value, fixture);
    validator("UsageReport").validate(&value).unwrap();
    assert_eq!(
        serde_json::from_str::<Value>(&quotio::output::json::render(&report).unwrap()).unwrap(),
        value
    );
    let mut invalid = value;
    invalid["providers"][0]["windows"][0]["quota"]["state"] = json!("invented");
    assert!(!validator("UsageReport").is_valid(&invalid));
}
