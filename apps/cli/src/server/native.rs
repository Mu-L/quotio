use super::*;
use crate::accounts::discovery::host::{self, Report};

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub(super) struct Request {
    #[serde(default)]
    providers: Vec<Provider>,
}

pub(super) async fn status(State(state): State<Arc<ApiState>>) -> Json<Report> {
    Json(state.native_discovery.read().await.clone())
}

pub(super) async fn start(
    State(state): State<Arc<ApiState>>,
    ApiJson(mut request): ApiJson<Request>,
) -> Result<(StatusCode, Json<Operation>), ApiError> {
    if !state.manage {
        return Err(ApiError(StatusCode::FORBIDDEN, "management_required"));
    }
    let vault = state.vault.clone().ok_or(ApiError(
        StatusCode::SERVICE_UNAVAILABLE,
        "account_storage_disabled",
    ))?;
    if request.providers.is_empty() {
        request.providers = state
            .settings
            .read()
            .await
            .values
            .providers()
            .map_err(|_| ApiError(StatusCode::BAD_REQUEST, "invalid_settings"))?;
    }
    request.providers.sort_by_key(|provider| provider.id());
    request.providers.dedup();
    let key = format!(
        "native-discovery:{}",
        serde_json::to_string(&request.providers)
            .map_err(|_| ApiError(StatusCode::BAD_REQUEST, "invalid_request"))?
    );
    let mut pending = state.pending.lock().await;
    if let Some(id) = pending.get(&key)
        && let Some(operation) = state.operations.lock().await.get(id)
    {
        return Ok((StatusCode::ACCEPTED, Json(operation)));
    }
    let (operation, _) = state
        .operations
        .lock()
        .await
        .start("discovery", None, key.clone())
        .map_err(operation_error)?;
    pending.insert(key.clone(), operation.id.clone());
    drop(pending);
    let work = state.clone();
    let id = operation.id.clone();
    let pending_key = key.clone();
    if let Err(error) = state.spawn(async move {
        let _scan = work.native_scan_lock.lock().await;
        let result = host::scan(
            vault,
            work.discovery.clone(),
            &request.providers,
            work.context.clock.now(),
        )
        .await;
        let result = match result {
            Ok(report) => {
                let changed = report.registered > 0;
                let mut current = work.native_discovery.write().await;
                current
                    .permissions
                    .retain(|source| !request.providers.contains(&source.provider));
                current
                    .known_sources
                    .retain(|source| !request.providers.contains(&source.provider));
                current
                    .failures
                    .retain(|failure| !request.providers.contains(&failure.provider));
                current
                    .scans
                    .retain(|scan| !request.providers.contains(&scan.provider));
                current.permissions.extend(report.permissions);
                current.known_sources.extend(report.known_sources);
                current.failures.extend(report.failures);
                current.scans.extend(report.scans);
                current.registered = report.registered;
                let value = serde_json::to_value(&*current).map_err(|_| "invalid_snapshot");
                drop(current);
                if changed {
                    work.invalidate().await;
                }
                value
            }
            Err(error) => Err(management::account_code(&error)),
        };
        work.operations.lock().await.finish(&id, result);
        work.pending.lock().await.remove(&key);
    }) {
        state.pending.lock().await.remove(&pending_key);
        state
            .operations
            .lock()
            .await
            .finish(&operation.id, Err("server_busy"));
        return Err(error);
    }
    Ok((StatusCode::ACCEPTED, Json(operation)))
}
