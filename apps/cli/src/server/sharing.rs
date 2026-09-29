//! A read-only companion listener shares the host's scheduler and vault.
use super::*;
use axum::Extension;
use serde::Deserialize;
use std::net::SocketAddr;

#[derive(Default)]
pub(super) struct Sharing {
    listener: Option<tokio::task::JoinHandle<()>>,
    address: Option<SocketAddr>,
    origin: Option<String>,
    active: Option<Arc<std::sync::atomic::AtomicBool>>,
    shutdown: Option<watch::Sender<bool>>,
}
impl Drop for Sharing {
    fn drop(&mut self) {
        self.stop();
    }
}
impl Sharing {
    fn view(&self) -> Value {
        json!({"schema_version":2,
               "enabled":self.listener.as_ref().is_some_and(|task| !task.is_finished()),
               "listen":self.address.map(|address| address.to_string()), "public_url":self.origin})
    }
    pub fn stop(&mut self) {
        if let Some(active) = self.active.take() {
            active.store(false, Ordering::SeqCst);
        }
        if let Some(shutdown) = self.shutdown.take() {
            shutdown.send_replace(true);
        }
        // Axum closes idle keep-alive connections and lets already-started reads finish.
        self.listener.take();
        self.address = None;
        self.origin = None;
    }
}
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub(super) struct Update {
    enabled: bool,
    listen: Option<SocketAddr>,
    public_url: Option<String>,
}
fn local_owner(principal: &security::Principal) -> Result<(), ApiError> {
    if principal.owner && principal.host_user {
        Ok(())
    } else {
        Err(ApiError(StatusCode::FORBIDDEN, "host_interaction_required"))
    }
}
pub(super) async fn get(
    State(state): State<Arc<ApiState>>,
    Extension(principal): Extension<security::Principal>,
) -> Result<Json<Value>, ApiError> {
    local_owner(&principal)?;
    Ok(Json(state.sharing.lock().await.view()))
}
pub(super) async fn update(
    State(state): State<Arc<ApiState>>,
    Extension(principal): Extension<security::Principal>,
    ApiJson(input): ApiJson<Update>,
) -> Result<Json<Value>, ApiError> {
    local_owner(&principal)?;
    let mut sharing = state.sharing.lock().await;
    if !input.enabled {
        sharing.stop();
        return Ok(Json(sharing.view()));
    }
    if state.vault.is_none() || state.no_saved_accounts {
        return Err(ApiError(
            StatusCode::SERVICE_UNAVAILABLE,
            "account_storage_disabled",
        ));
    }
    let address = input
        .listen
        .filter(|address| address.ip().is_loopback() && address.port() != 0)
        .ok_or(ApiError(StatusCode::BAD_REQUEST, "invalid_share_address"))?;
    let origin = input
        .public_url
        .ok_or(ApiError(StatusCode::BAD_REQUEST, "invalid_public_url"))?;
    let active = Arc::new(std::sync::atomic::AtomicBool::new(true));
    let policy = security::Policy::companion(address, &origin, active.clone())
        .map_err(|_| ApiError(StatusCode::BAD_REQUEST, "invalid_public_url"))?;
    if sharing.address == Some(address)
        && sharing.origin.as_deref() == Some(&origin)
        && sharing
            .listener
            .as_ref()
            .is_some_and(|task| !task.is_finished())
    {
        return Ok(Json(sharing.view()));
    }
    // Never tear down a working endpoint to attempt a bind on a different port.
    if sharing.address == Some(address) {
        return Err(ApiError(
            StatusCode::CONFLICT,
            "disable_sharing_before_changing_origin",
        ));
    }
    let listener = TcpListener::bind(address)
        .await
        .map_err(|_| ApiError(StatusCode::CONFLICT, "share_port_unavailable"))?;
    sharing.stop();
    let router = router(state.clone(), Arc::new(policy));
    let (shutdown, mut stopped) = watch::channel(false);
    sharing.shutdown = Some(shutdown);
    sharing.active = Some(active);
    sharing.listener = Some(tokio::spawn(async move {
        if axum::serve(listener, router)
            .with_graceful_shutdown(async move {
                let _ = stopped.wait_for(|value| *value).await;
            })
            .await
            .is_err()
        {
            tracing::warn!("companion_listener_stopped");
        }
    }));
    sharing.address = Some(address);
    sharing.origin = Some(origin);
    Ok(Json(sharing.view()))
}

#[cfg(test)]
mod tests {
    use super::*;
    #[tokio::test]
    async fn companion_listener_preserves_local_owner_and_rejects_remote_authority() {
        let (mut state, directory, _) = crate::server::tests::fixture().await;
        Arc::get_mut(&mut state).unwrap().no_saved_accounts = false;
        let vault = state.vault.clone().unwrap();
        let grant = crate::accounts::clients::create(
            vault.clone(),
            crate::accounts::clients::Create {
                label: "Synthetic phone".into(),
                scope: crate::accounts::clients::Scope::Read,
                expires_in_seconds: 60,
            },
            state.context.clock.now(),
        )
        .await
        .unwrap();
        let local = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let local_address = local.local_addr().unwrap();
        let owner = "synthetic-local-owner-secret-123456";
        let app = router(
            state.clone(),
            Arc::new(
                security::Policy::new(local_address, true, None, &[], Some(owner.into())).unwrap(),
            ),
        );
        let server = tokio::spawn(async move { axum::serve(local, app).await.unwrap() });
        let candidate = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = candidate.local_addr().unwrap();
        drop(candidate);
        let client = reqwest::Client::new();
        let base = format!("http://{local_address}");
        let response = client.put(format!("{base}/v2/sharing")).bearer_auth(owner)
            .json(&json!({"enabled":true,"listen":address.to_string(),"public_url":"https://companion.example.test"}))
            .send().await.unwrap();
        assert_eq!(response.status(), 200);
        let remote = format!("http://{address}");
        let status: Value = client
            .get(format!("{remote}/v2/status"))
            .bearer_auth(&grant.token)
            .send()
            .await
            .unwrap()
            .json()
            .await
            .unwrap();
        assert_eq!(status["access_mode"], "read_only");
        assert_eq!(status["client_id"], grant.client.id);
        assert_eq!(
            client
                .get(format!("{remote}/v2/status"))
                .bearer_auth(owner)
                .send()
                .await
                .unwrap()
                .status(),
            401
        );
        assert_eq!(
            client
                .post(format!("{remote}/v2/refresh"))
                .bearer_auth(&grant.token)
                .json(&json!({}))
                .send()
                .await
                .unwrap()
                .status(),
            405
        );
        assert_eq!(
            client
                .get(format!("{remote}/v2/clients"))
                .bearer_auth(&grant.token)
                .send()
                .await
                .unwrap()
                .status(),
            403
        );
        let local_status: Value = client
            .get(format!("{base}/v2/status"))
            .bearer_auth(owner)
            .send()
            .await
            .unwrap()
            .json()
            .await
            .unwrap();
        assert_eq!(local_status["access_mode"], "manage");
        let second = crate::accounts::clients::create(
            vault.clone(),
            crate::accounts::clients::Create {
                label: "Second phone".into(),
                scope: crate::accounts::clients::Scope::Read,
                expires_in_seconds: 60,
            },
            state.context.clock.now(),
        )
        .await
        .unwrap();
        assert_eq!(
            client
                .get(format!("{remote}/v2/status"))
                .bearer_auth(&second.token)
                .send()
                .await
                .unwrap()
                .status(),
            200
        );
        crate::accounts::clients::revoke(vault, grant.client.id)
            .await
            .unwrap();
        assert_eq!(
            client
                .get(format!("{remote}/v2/status"))
                .bearer_auth(&grant.token)
                .send()
                .await
                .unwrap()
                .status(),
            401
        );
        assert_eq!(
            client
                .put(format!("{base}/v2/sharing"))
                .bearer_auth(owner)
                .json(&json!({"enabled":false}))
                .send()
                .await
                .unwrap()
                .status(),
            200
        );
        if let Ok(response) = client
            .get(format!("{remote}/v2/status"))
            .bearer_auth(&second.token)
            .send()
            .await
        {
            assert_eq!(response.status(), 503);
        }
        server.abort();
        std::fs::remove_dir_all(directory).unwrap();
    }
}
