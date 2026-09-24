# Resolved host contract v2

This is the initial typed contract, not an available `/v2` endpoint yet. v1 CLI and HTTP remain unchanged. The definitions are published under `V2*` in `openapi.json`; Rust types live in `src/contract.rs`. No frontend should switch production traffic until the resolved account service, persistent IDs/revisions and migration are implemented.

## Resource ownership

Rust supplies final account display names, stable opaque account IDs, separate source IDs, source selection, identity evidence, action availability and usage freshness. A frontend must not select names or merge accounts based on provider, email, username or credential location. A source's `location` is a semantic code, never a host path.

`user_label` is an explicit override, not a generated name. Identity evidence is `unknown`, `local` or `verified`. Local names may be displayed but are not sufficient proof to merge sources. Provider and tenant scoping belongs to Rust resolution, not client-side matching.

Each usage entry references one account. Source IDs are unique across a host snapshot; at most one enabled source is selected for an enabled account. A host's persisted revision must increase as its state changes; comparing revisions across different host IDs is invalid. Clients store selections by `(host.id, account.id)`, never display name.

## JSON and compatibility

- `schema_version` is exactly 2. Unsupported major versions must be rejected before changing frontend state.
- Every documented field is present. Optional values are explicit `null`; collections are empty arrays/maps, not null. Timestamps use RFC 3339.
- Server output is checked against closed schemas to detect accidental or sensitive fields. Clients tolerate additional fields introduced compatibly, but must not infer meaning for unknown action/state/metric kinds.
- `display_name` is render-ready public metadata; localization of semantic actions, units and dates remains a client concern.
- `not_loaded`, `fresh`, `stale` and `unavailable` are distinct. Empty metrics with a valid plan are supported. Unknown, disabled, unlimited and measured quota must not be collapsed into zero.
- Action `interaction` distinguishes work on the client, work on the host, and a person required at the host. This is not permission to bypass OS approval. Credentials never occur in these response types.
- A snapshot contains resolved accounts and usage atomically. It is not a request to rescan credentials or call provider APIs. Account lists must remain available without network refresh.
- v1 routes and CLI JSON keep their existing schema and IDs. A future v2 transport must be selected explicitly during migration. The types do not authorize a storage migration or remote network listener.

## Checks

`cargo test --locked --test contract` validates real serializers against JSON Schema, rejects bad types/states, checks cross-resource references, and compares the shared fixtures. `tests/fixtures/contracts/snapshot-v2.json` covers a plan-only Copilot account and one Devin account with two sources. These fixtures are synthetic, not exported user data.
