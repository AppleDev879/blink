# Blink — Sparkle auto-updates

Blink uses **[Sparkle 2.x](https://sparkle-project.org/)** (SPM, currently **2.10.1+**) for non–App Store updates. Menu bar → **Check for Updates…** runs an interactive check; quiet background checks run about once per day (`SUEnableAutomaticChecks` + `SUScheduledCheckInterval` = 86400).

## Feed URL (canonical)

```
https://github.com/AppleDev879/blink/releases/latest/download/appcast.xml
```

Attach an asset named **`appcast.xml`** on every GitHub Release (or keep the latest release’s appcast current). That URL is set as `SUFeedURL` in `Blink/Info.plist`. Do not change it without shipping a new app that points elsewhere.

## EdDSA keys (required before first real update)

Sparkle 2 uses **EdDSA** (`SUPublicEDKey`). DSA is legacy — do not use it.

### Generate (once)

After resolving packages (or from a Release build’s Sparkle artifact):

```bash
# From DerivedData / SPM artifacts after a local build:
#   …/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys
#
# Or download Sparkle-*.tar.xz from
#   https://github.com/sparkle-project/Sparkle/releases
# and use bin/generate_keys

generate_keys --account blink
```

- Allow Keychain access when prompted.
- Copy the printed **public** key into `Blink/Info.plist` → `SUPublicEDKey` (replace `REPLACE_WITH_EDDSA_PUBLIC_KEY`).
- Prefer `--account blink` so the key is namespaced for this product.

### Private key storage (never commit)

| What | Where |
| --- | --- |
| Private key (default) | macOS **login Keychain** item for account `blink` (“Private key for signing Sparkle updates”) |
| Optional export backup | `~/Library/Application Support/Blink/sparkle/eddsa_priv.pem` (create the directory; mode `600`) |

Export a backup only to encrypted backup / password manager — **never** into the git repo, PR, CI logs, or chat:

```bash
mkdir -p "$HOME/Library/Application Support/Blink/sparkle"
chmod 700 "$HOME/Library/Application Support/Blink/sparkle"
generate_keys --account blink -x "$HOME/Library/Application Support/Blink/sparkle/eddsa_priv.pem"
chmod 600 "$HOME/Library/Application Support/Blink/sparkle/eddsa_priv.pem"
```

Import on another Mac:

```bash
generate_keys --account blink -f "$HOME/Library/Application Support/Blink/sparkle/eddsa_priv.pem"
```

`eddsa_priv.pem`, `sparkle-keys/`, and related patterns are gitignored.

### Public key in the app

`SUPublicEDKey` ships inside the app bundle. After you paste the real public key, bump `CFBundleVersion` / marketing version as usual and ship that build as the baseline that can verify future updates.

## Release recipe

1. **Bump versions** in `Blink/Info.plist` (`CFBundleShortVersionString`, `CFBundleVersion`) and Xcode `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` if you keep them in sync.
2. **Archive** a Release build with **Hardened Runtime** and **Developer ID Application** signing.
3. **Notarize** the app (and preferably the DMG), then **staple**:
   ```bash
   xcrun notarytool submit Blink-1.x.x.dmg --wait --keychain-profile "AC_NOTARY"
   xcrun stapler staple Blink-1.x.x.dmg
   ```
4. **Sign the update archive** for Sparkle (DMG or ZIP of the `.app`):
   ```bash
   sign_update Blink-1.x.x.dmg
   # prints sparkle:edSignature=… and length=…
   ```
   If the private key is a file instead of Keychain:
   ```bash
   sign_update Blink-1.x.x.dmg -f "$HOME/Library/Application Support/Blink/sparkle/eddsa_priv.pem"
   ```
5. **Write / update `appcast.xml`** (see `sparkle/appcast.example.xml`). Set:
   - `enclosure url` → GitHub Release asset URL for that version’s DMG/ZIP  
   - `sparkle:version` → `CFBundleVersion`  
   - `sparkle:shortVersionString` → marketing version  
   - `sparkle:edSignature` + `length` from `sign_update`  
   - `sparkle:minimumSystemVersion` → `14.0` (Blink) — Sparkle 2.10+ also expects ≥ 12.0 for the framework itself  
6. **Publish** a GitHub Release `vX.Y.Z` with:
   - `Blink-X.Y.Z.dmg` (or `.zip`)
   - `appcast.xml` (same filename every time so `…/latest/download/appcast.xml` works)
7. Smoke: install the previous signed build → **Check for Updates…** → install → relaunch.

Optional helper: Sparkle’s `generate_appcast` can build the feed from a folder of archives if you prefer automation over hand-editing XML.

## Local development notes

- Debug / ad-hoc signed builds will not exercise a production update path; that is expected.
- Unit tests must **not** hit the network for updates. Sparkle is only started from the app process; `BlinkTests` does not import Sparkle update flows.
- Until `SUPublicEDKey` is a real key and an appcast exists, **Check for Updates…** may show an error dialog — fine pre-release.

## References

- [Sparkle documentation](https://sparkle-project.org/documentation/)
- [Signing updates](https://sparkle-project.org/documentation/#3-signing)
- Project distribution overview: Agent Store `docs/distribution-options.md` (Sparkle section)
