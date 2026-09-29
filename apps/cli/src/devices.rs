//! Owner-side device management. Credentials are read from the environment, never argv.
use crate::cli::{DeviceCommand, DevicesArgs};
use serde_json::{Value, json};
use std::time::Duration;

pub async fn run(args: DevicesArgs) -> Result<Value, &'static str> {
    let base = reqwest::Url::parse(&args.api).map_err(|_| "invalid_local_api")?;
    if base.scheme() != "http"
        || !matches!(base.host_str(), Some("127.0.0.1" | "[::1]"))
        || !base.username().is_empty()
        || base.password().is_some()
        || base.query().is_some()
        || base.fragment().is_some()
        || base.path() != "/"
    {
        return Err("invalid_local_api");
    }
    let token = std::env::var("QUOTIO_SERVER_TOKEN").map_err(|_| "server_token_required")?;
    if !(32..=4096).contains(&token.len()) || !token.bytes().all(|b| b.is_ascii_graphic()) {
        return Err("invalid_server_token");
    }
    let client = reqwest::Client::builder()
        .redirect(reqwest::redirect::Policy::none())
        .timeout(Duration::from_secs(20))
        .build()
        .map_err(|_| "client_unavailable")?;
    let (method, path, body, origin) = match args.command {
        DeviceCommand::Add {
            label,
            public_url,
            expires_in_seconds,
        } => {
            let origin = reqwest::Url::parse(&public_url).map_err(|_| "invalid_public_url")?;
            if origin.scheme() != "https"
                || origin.host_str().is_none()
                || !origin.username().is_empty()
                || origin.password().is_some()
                || origin.path() != "/"
                || origin.query().is_some()
                || origin.fragment().is_some()
            {
                return Err("invalid_public_url");
            }
            (
                reqwest::Method::POST,
                "v2/clients".to_owned(),
                Some(json!({"label":label,"scope":"read","expires_in_seconds":expires_in_seconds})),
                Some(origin.origin().ascii_serialization()),
            )
        }
        DeviceCommand::List => (reqwest::Method::GET, "v2/clients".into(), None, None),
        DeviceCommand::Revoke { id } => {
            if !crate::contract::valid_id(&id) {
                return Err("invalid_client_id");
            }
            (
                reqwest::Method::DELETE,
                format!("v2/clients/{id}"),
                None,
                None,
            )
        }
    };
    let mut request = client
        .request(method, base.join(&path).map_err(|_| "invalid_local_api")?)
        .bearer_auth(token);
    if let Some(body) = body {
        request = request.json(&body);
    }
    let response = request.send().await.map_err(|_| "host_unavailable")?;
    if !response.status().is_success() {
        return Err("device_request_rejected");
    }
    if response.status() == reqwest::StatusCode::NO_CONTENT {
        return Ok(json!({"revoked":true}));
    }
    let value: Value = response.json().await.map_err(|_| "invalid_host_response")?;
    if let Some(origin) = origin {
        // Issuance is not retried. A lost response must be revoked by ID before reissuing.
        if value["schema_version"] != 2
            || value["client"]["scope"] != "read"
            || !value["token"].is_string()
            || !value["host_id"].is_string()
        {
            return Err("invalid_host_response");
        }
        return Ok(
            json!({"pairing_version":1,"origin":origin,"host_id":value["host_id"],
                         "client_id":value["client"]["id"],"expires_at":value["client"]["expires_at"],"token":value["token"]}),
        );
    }
    Ok(value)
}
