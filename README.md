# Quotio

Quotio is a monorepo for tools that monitor AI coding quotas and operate
CLIProxyAPI.

## Projects

- [macOS app](apps/macos/README.md) — native SwiftUI menu bar and window app.
- [CLI](apps/cli/README.md) — cross-platform Rust command-line client.
- [`QuotioCore`](Packages/QuotioCore) — Swift package used by the Apple app.

## Development

```bash
# macOS core and architecture
swift test --package-path Packages/QuotioCore
./apps/macos/scripts/check_architecture.sh

# CLI
cargo test --manifest-path apps/cli/Cargo.toml --locked --all-features
```

The macOS app uses `v*` release tags. The CLI uses `cli-v*` tags so both
products can publish releases from this repository without colliding.

See each project README for build, run, and release instructions.
