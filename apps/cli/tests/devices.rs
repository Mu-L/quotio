use axum::{
    Json, Router,
    http::{HeaderMap, StatusCode},
    routing::{delete, get},
};
use serde_json::{Value, json};
use std::sync::{
    Arc,
    atomic::{AtomicUsize, Ordering},
};

const OWNER: &str = "synthetic-device-owner-token-1234567890";

#[tokio::test]
async fn device_commands_issue_once_list_revoke_and_refuse_remote_owner_transport() {
    let issued = Arc::new(AtomicUsize::new(0));
    let count = issued.clone();
    let router = Router::new()
        .route("/v2/sharing", get(|| async { Json(json!({"enabled":true,"public_url":"https://192.168.1.10:6768","certificate":"AQID"})) }))
        .route(
            "/v2/clients",
            get(|| async { Json(json!({"schema_version":2,"clients":[{"id":"phone"}]})) }).post(
                move |headers: HeaderMap, Json(body): Json<Value>| async move {
                    assert_eq!(headers["authorization"], format!("Bearer {OWNER}"));
                    assert_eq!(body["scope"], "read");
                    assert_eq!(body["label"], "iPhone");
                    count.fetch_add(1, Ordering::SeqCst);
                    (
                        StatusCode::CREATED,
                        Json(json!({"schema_version":2,"host_id":"host-fixture",
                    "client":{"id":"phone","scope":"read","expires_at":"2030-01-01T00:00:00Z"},
                    "token":"synthetic-phone-credential"})),
                    )
                },
            ),
        )
        .route(
            "/v2/clients/phone",
            delete(|| async { StatusCode::NO_CONTENT }),
        );
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let origin = format!("http://{}", listener.local_addr().unwrap());
    let server = tokio::spawn(async move { axum::serve(listener, router).await.unwrap() });
    for (arguments, expected) in [
        (
            vec![
                "add",
                "--label",
                "iPhone",
                "--public-url",
                "https://host.example.test",
            ],
            "pairing_version",
        ),
        (vec!["list"], "clients"),
        (vec!["revoke", "phone"], "revoked"),
    ] {
        let output = tokio::process::Command::new(env!("CARGO_BIN_EXE_quotio"))
            .args(["devices", "--api", &origin])
            .args(arguments)
            .env("QUOTIO_SERVER_TOKEN", OWNER)
            .output()
            .await
            .unwrap();
        assert!(output.status.success());
        let value: Value = serde_json::from_slice(&output.stdout).unwrap();
        assert!(value.get(expected).is_some());
        if expected == "pairing_version" {
            assert_eq!(value["pairing_version"], 1);
            assert_eq!(value["origin"], "https://host.example.test");
            assert_eq!(value["client_id"], "phone");
            assert_eq!(value["token"], "synthetic-phone-credential");
        }
        assert!(!String::from_utf8_lossy(&output.stdout).contains(OWNER));
        assert!(!String::from_utf8_lossy(&output.stderr).contains(OWNER));
    }
    assert_eq!(issued.load(Ordering::SeqCst), 1);
    let direct = tokio::process::Command::new(env!("CARGO_BIN_EXE_quotio"))
        .args([
            "devices",
            "--api",
            &origin,
            "add",
            "--label",
            "iPhone",
            "--public-url",
            "https://192.168.1.10:6768",
        ])
        .env("QUOTIO_SERVER_TOKEN", OWNER)
        .output()
        .await
        .unwrap();
    assert!(direct.status.success());
    let value: Value = serde_json::from_slice(&direct.stdout).unwrap();
    assert_eq!(value["pairing_version"], 2);
    assert_eq!(value["certificate"], "AQID");
    assert_eq!(issued.load(Ordering::SeqCst), 2);
    let refused = tokio::process::Command::new(env!("CARGO_BIN_EXE_quotio"))
        .args(["devices", "--api", "https://remote.example.test", "list"])
        .env("QUOTIO_SERVER_TOKEN", OWNER)
        .output()
        .await
        .unwrap();
    assert!(!refused.status.success());
    assert!(String::from_utf8_lossy(&refused.stderr).contains("invalid_local_api"));
    assert!(!String::from_utf8_lossy(&refused.stderr).contains(OWNER));
    server.abort();
}
