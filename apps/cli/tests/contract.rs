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

#[test]
fn resolved_v2_snapshot_roundtrips_and_enforces_account_source_boundaries() {
    use quotio::contract::Snapshot;
    let fixture: Value =
        serde_json::from_str(include_str!("fixtures/contracts/snapshot-v2.json")).unwrap();
    validator("V2Snapshot").validate(&fixture).unwrap();
    let snapshot: Snapshot = serde_json::from_value(fixture.clone()).unwrap();
    snapshot.validate().unwrap();
    assert_eq!(serde_json::to_value(&snapshot).unwrap(), fixture);
    assert!(snapshot.usage[0].metrics.is_empty()); // Valid plan-only account.
    assert_eq!(snapshot.accounts[1].sources.len(), 2); // One account, two sources.
    for mutate in [
        |s: &mut Snapshot| s.accounts[1].id = s.accounts[0].id.clone(),
        |s: &mut Snapshot| s.accounts[1].sources[0].id = s.accounts[0].sources[0].id.clone(),
        |s: &mut Snapshot| s.usage[0].account_id = "missing".into(),
        |s: &mut Snapshot| s.accounts[1].sources[1].selected = true,
        |s: &mut Snapshot| s.accounts[0].enabled = false,
        |s: &mut Snapshot| s.schema_version = 1,
    ] {
        let mut invalid = snapshot.clone();
        mutate(&mut invalid);
        assert!(invalid.validate().is_err());
    }
    let mut missing = fixture.clone();
    missing["accounts"][0]
        .as_object_mut()
        .unwrap()
        .remove("display_name");
    assert!(!validator("V2Snapshot").is_valid(&missing));
    let mut invalid = fixture;
    invalid["usage"][0]["freshness"] = json!("invented");
    assert!(!validator("V2Snapshot").is_valid(&invalid));
}
