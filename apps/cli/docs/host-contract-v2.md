# Resolved host contract v2

The resolved account read API initializes its protected metadata automatically on first access. Resolved snapshots are available at `GET /v2/snapshot`; macOS reads its account and quota state from this endpoint. There is no CLI schema-selection flag or compatibility guarantee for the old account array. Older production routes are being removed as the frontend cutover proceeds. The definitions are published under `V2*` in `openapi.json`; Rust types live in `src/contract.rs`. The macOS account CRUD now uses v2 account/source resources; discovery and authentication orchestration are the remaining transport cutover work.

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
- The resolved model is the default contract. Existing credentials and source IDs are retained during data migration; old API shapes and schema-selection flags are not supported. Remote listeners still require a separate secure transport implementation.

## Checks

`cargo test --locked --test contract` validates real serializers against JSON Schema, rejects bad types/states, checks cross-resource references, and compares the shared fixtures. `tests/fixtures/contracts/snapshot-v2.json` covers a plan-only Copilot account and one Devin account with two sources. These fixtures are synthetic, not exported user data.

## Persisted naming provenance

New account creation records whether its label is user-supplied or generated. Successful managed refreshes cache the provider's name in the protected account document. CLI account listing, HTTP account serialization and managed usage share Rust's `Account::display_name` policy: explicit user label wins; generated labels may use the last observed provider name. A rename becomes an explicit user label and invalidates the old usage-cache key. Replacing a credential with a different identity clears its previously observed name.

Documents without naming provenance retain their stored labels. Reading an old vault does not migrate it, and existing sources are not guessed to be user-named/generated from string patterns. This preserves ambiguous legacy customization until explicit migration. Imported legacy account metadata likewise keeps unknown provenance.

Naming-aware writes require protected vault format 9. Readers reject naming metadata in older format numbers, and older binaries that only accept formats 1–8 must refuse format 9 rather than silently drop the new policy. Credential contents, account IDs, enabled state and refresh ownership are unchanged by naming observations. This is the naming portion of persistence; verified identity grouping, durable logical-account mappings and v2 runtime routes are still pending.

## Verified identity registry

Vault format 10 stores the resolved-account registry. Enabling it preserves every credential record and original source ID, starts logical account IDs from those stable IDs, and assigns a persistent host ID. Successful commits advance a checked monotonic revision. Reading the resolved account view initializes the registry if absent, then returns its committed revision.

Only `VerifiedIdentity { subject, tenant }` supplied by a fresh authenticated provider fetch can merge sources of the same provider. Labels, emails, local metadata, token fingerprints and cached/client-supplied reports are not identity proof. Devin Desktop currently emits evidence from `GetUserStatus.userId` and `teamId`; other adapters remain unverified until their identity endpoints are audited. Missing evidence does not invalidate a working login; its source stays distinct.

Merging an unverified source into a confirmed account retains a durable redirect for its earlier logical ID. Switching a source to a different verified identity or explicitly replacing its credential never redirects an old account bookmark to the new person. Deleting one source retains the logical ID while another source remains. Corrupt cross-provider or unverified shared bindings are rejected on read.

Data migration preserves current credentials, source IDs, names and enabled state. A failed write must leave the previous document intact. Downgrading to old API/storage behavior is not part of this migration.

## Default account read API

- CLI: `quotio accounts list --format json` emits the resolved account envelope; no `--schema-version` or initialization command is required. Text output formats the same Rust account projection.
- HTTP: `GET /v2/accounts` uses the same service. First access atomically initializes protected metadata, preserving original source IDs and credentials. Repeated reads keep the host ID and revision stable.
- CLI `use` and `remove` accept logical account IDs, including a group whose original source was removed. Removing a logical account unlinks all its registered sources, never external provider login files.
- The standalone CLI's default vault is not the macOS app's isolated vault. Use the appropriate host connection; never merge namespaces implicitly.
- Account-list reads report `not_checked`; use `/v2/snapshot` for source health and quota state. It advertises the supported logical-account and source actions. Provider discovery and authentication are still being moved out of the frontend.

## Logical account and source mutations

- `POST /v2/accounts` accepts the typed credential intake already documented for account creation. It returns an idempotent operation; no credential is returned.
- `GET/PATCH/DELETE /v2/accounts/{id}` resolves a logical account or a persisted redirect. PATCH supports `user_label` (null resets, omission preserves), `enabled` for every source in the group, and `active: true` to select an enabled source. DELETE unlinks the entire group.
- `PATCH/DELETE /v2/sources/{id}` targets exactly one physical source record. PATCH accepts boolean `enabled` and replacement `api_key` for owned API-key sources. Replacement validates with the provider before committing; omitted settings/region/organization are preserved and null resets them. Settings changes require a replacement key. A changed credential during validation rejects the write. A new identity detaches the source and returns its new logical account ID. DELETE leaves the logical account alive while another source remains. Neither operation edits the provider's external login.
- Writes require bearer authentication, management mode and an `Idempotency-Key`. They use the existing durable mutation ledger and operation polling. A conflicting body with the same key is rejected.
- Logical user labels live in the protected registry, independent of source labels, so deleting the original source does not drop the account name. Format 11 records this policy. Display precedence and action availability are decided in Rust; frontends forward the selected resource scope.

## Resolved snapshots

`GET /v2/snapshot` combines registered accounts with collected observations. Rust chooses one enabled source per account, preferring fresh results over stale results and a working source over a failed source. It preserves metric states, amounts, notes, reset descriptions and provider supplemental observations. A secondary source failure stays on that source instead of hiding another source's quota. A plan-only success has no invented metrics. Failed unregistered login probes appear in `provider_issues` and do not create account rows.

Snapshot reads use the current vault under its transaction lock. Deleted sources cannot reappear from an old report, and replacing an API-key identity discards that identity's old quota. Format 12 persists a digest of account/usage state: the revision increases when those values change, including freshness transitions, but not on an unchanged read. The response is published only after the revision commits.

With `--no-saved-accounts`, snapshots do not access the protected vault. Default/environment/mock observations remain visible with no account-write actions. This mode's host ID and revision are scoped to the server session; restarting it creates a new host ID. Normal account-backed hosts retain the vault's host ID across restarts.

## CLI quota output

`quotio usage --format json` emits the same `Snapshot` shape as `/v2/snapshot`; text output formats its resolved names, IDs and selected metrics. Provider/account filters limit the returned accounts. `--account` resolves a logical account and collects its enabled sources, including after the original source was unlinked. The no-saved-account path performs no protected-vault read. Internal per-source cache records are not a public output format.

`account_redirects` contains persisted logical-account redirects. Source IDs are a separate scope and must never be inferred as redirects; a reassigned source must not retarget an old account bookmark. Loaded usage requires a fetch timestamp. Duplicate metric IDs, invalid graph references and duplicate profile dates are rejected before rendering. Malformed collected data reports `invalid_snapshot`, not a credential-storage permission error.

## Host-owned OAuth callbacks

When `callback_mode` is omitted, Rust selects it from the provider workflow. Browser-callback flows use the host's loopback listener; device and manual-code flows remain session-driven. The frontend opens the supplied HTTPS URL, displays a supplied user code or manual-code form, and polls the session. Only the host declares expiry or completion. Cancelling an attempt requests host cancellation, including when the frontend task itself was cancelled. Completed accounts are read by logical ID; the frontend never synthesizes a name or account when that read fails.

## Native discovery

`POST /v2/discovery` starts a host discovery operation for the requested provider IDs, or the configured providers when omitted. Rust selects supported native source kinds, inspects metadata without prompting, registers readable sources, and reports permission requests separately. `GET /v2/discovery` returns the complete current report, including per-provider scan times, known sources and failures. A scoped scan preserves other providers' discovery results.

Repeated registration of an existing source is a no-op: it preserves disabled state, does not rewrite the borrowed login and does not append another mutation receipt. The frontend submits scan/authorization commands and renders one discovery snapshot; it no longer loops over source kinds or persists discovery decisions in UserDefaults. Automatic scheduling and durable scan suppression are separate host settings work.

## Removed native sources

Vault format 13 records suppression for removed native source identities and their permission locations. Automatic scans do not recreate those references or repeat their permission prompts. Explicit `restore_removed: true` discovery clears suppression only for the selected providers; existing disabled sources remain disabled. The app's Scan Again action sends this explicit restore intent. Discovery reads recheck current registered/suppressed sources so a removed source is not kept in permission state solely by an older scan report. External login files and Keychain items remain unchanged.
