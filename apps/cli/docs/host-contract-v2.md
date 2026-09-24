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

## Persisted naming provenance

New account creation records whether its label is user-supplied or generated. Successful managed refreshes cache the provider's name in the protected account document. CLI account listing, HTTP account serialization and managed usage share Rust's `Account::display_name` policy: explicit user label wins; generated labels may use the last observed provider name. A rename becomes an explicit user label and invalidates the old usage-cache key. Replacing a credential with a different identity clears its previously observed name.

Documents without naming provenance retain their stored labels. Reading an old vault does not migrate it, and existing sources are not guessed to be user-named/generated from string patterns. This preserves ambiguous legacy customization until explicit migration. Imported legacy account metadata likewise keeps unknown provenance.

Naming-aware writes require protected vault format 9. Readers reject naming metadata in older format numbers, and older binaries that only accept formats 1–8 must refuse format 9 rather than silently drop the new policy. Credential contents, account IDs, enabled state and refresh ownership are unchanged by naming observations. This is the naming portion of persistence; verified identity grouping, durable logical-account mappings and v2 runtime routes are still pending.

## Verified identity registry

Vault format 10 adds an explicit, opt-in resolved-account registry. Enabling it preserves every credential record and original source ID, starts logical account IDs from those stable IDs, and assigns a persistent host ID. Successful commits advance a checked monotonic revision. Reading a legacy vault does not enable the registry.

Only `VerifiedIdentity { subject, tenant }` supplied by a fresh authenticated provider fetch can merge sources of the same provider. Labels, emails, local metadata, token fingerprints and cached/client-supplied reports are not identity proof. Devin Desktop currently emits evidence from `GetUserStatus.userId` and `teamId`; other adapters remain unverified until their identity endpoints are audited. Missing evidence does not invalidate a working login; its source stays distinct.

Merging an unverified source into a confirmed account retains a durable redirect for its earlier logical ID. Switching a source to a different verified identity or explicitly replacing its credential never redirects an old account bookmark to the new person. Deleting one source retains the logical ID while another source remains. Corrupt cross-provider or unverified shared bindings are rejected on read.

Metadata-only rollback removes the registry and returns to format 9, retaining current credentials, source IDs, names and enabled state. It never restores old tokens from a pre-migration backup. Runtime v2 routes and frontend cutover remain disabled until the resolved read/CRUD services are wired and tested.
