# Pastel — IPA Download Tool

## Repo structure

Two-part macOS app (Swift UI frontend + Node.js backend), no CI/tests/lint.

```
Pastel/PastelApp.swift    ← single-file SwiftUI app (~8300 lines), plus compat shims at the bottom
NodeProject/main.js       ← CLI entrypoint (ESM)
NodeProject/src/          ← backend: gsa.js, client.js, catalog.js, downloader.js, ipa.js, Signature.js, device.js, i18n.js
node/bin/node             ← bundled arm64 Node binary (copied into .app by build phase)
```

## Build & run

1. `cd NodeProject && npm install`
2. Open `Pastel.xcodeproj` in Xcode, build & run (arm64 only)

CI: `.github/workflows/build.yml` builds on `macos-15`. Override `MACOSX_DEPLOYMENT_TARGET=15.0` since the code uses macOS 26+ SwiftUI APIs (`glassEffect`, `GlassEffectContainer`, `safeAreaBar`, etc.) shimmed at the bottom of `PastelApp.swift`.

No tests, no lint, no typecheck — no verification commands exist.

## Architecture

Swift app spawns `node/bin/node main.js` as a subprocess via `Process`. Communication is one-way: env vars in, JSON/progress on stdout. The Swift side never reads Node's stderr directly — it parses `@@IPA:` prefix markers from stdout for progress events.

Key env vars fed to the Node process:
- `APPLE_ID`, `APPLE_PWD`, `APPLE_CODE` (2FA code)
- `DOWNLOAD_APPID`, `DOWNLOAD_VERSION_ID`
- `IPA_VALIDATE_LOGIN`, `IPA_LIST_VERSION_IDS`, `IPA_DEVICE_GUID`

## Node CLI

```bash
node main.js search --term=<query>
node main.js lookup --id=<appId>
node main.js featured
node main.js versions --id=<appId>
```

Or run full download via env vars (no subcommand).

## Notable details

- **GSA login** (`src/gsa.js`): SRP-6a via curl subprocess with Anisette + 2FA; session cached to disk.
- **Device GUID** (`src/device.js`): MAC-derived (en0/en1), stored in Keychain, reduces 2FA prompts.
- **IPA signing** (`src/Signature.js`): SINF injection + metadata patching after download.
- **Localization**: `Pastel/Localizable.xcstrings` (6 languages). `PatchSparkleLocalizations.sh` post-processes Sparkle's Chinese strings in the built bundle.
- **Sparkle** for auto-update (via SPM `~> 2.9.3`); feed config is `appcast.xml`.
- **No .env.example** — create `.env` from scratch for Node backend testing.
