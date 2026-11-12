# LineScroll

iPhone-first SwiftUI MVP: browse/search Project Gutenberg texts (via [Gutendex](https://gutendex.com)), download plain text offline, and read **one TextKit layout line at a time** with vertical snap paging.

LineScroll is an independent app. It is **not** a Project Gutenberg trademarked product; PG is credited as the source of public-domain texts.

## Requirements

- macOS with **Xcode 15+**
- iOS **17+** simulator or device
- Network access for catalog search / downloads (a bundled Pride & Prejudice excerpt works offline)

## Open & run

```bash
open LineScroll/LineScroll.xcodeproj
```

1. Select the **LineScroll** scheme and an iPhone simulator (or your device).
2. Set your **Team** under Signing & Capabilities if running on a device (`PRODUCT_BUNDLE_IDENTIFIER` is `io.abarrett.LineScroll`).
3. Press Run (⌘R).

Suggested first path: **Library** → open the sample excerpt → swipe up/down to snap lines. Then **Browse** → search → download a plain-text title → read offline.

## What the MVP includes

| Feature | Notes |
| --- | --- |
| Browse / search | Gutendex JSON (`languages=en`, prefers `text/plain`) |
| Download | Plain-text URL from catalog formats; identifying User-Agent |
| Offline library | Files under Documents; swipe to delete |
| One-line reader | UIKit `UICollectionView` paging + TextKit (`NSLayoutManager`) line breaks |
| Resume | Persists character offset; remaps after font/width changes |
| Font size | Settings slider (serif system design) |
| Light / dark | System / Light / Dark |
| Progress | Line index + percent chrome (tap to toggle) |
| Credit / disclaimer | Settings → Project Gutenberg credit & disclaimer |

## Gutendex usage

- Base: `https://gutendex.com/books/`
- User-Agent: `LineScroll/1.0 (iOS; https://github.com/AppleDev879/blink; contact: abarrett879@gmail.com)`
- Fine for prototypes. Production should prefer a self-hosted index from the official PG RDF/CSV dump and approved mirrors (see Project Gutenberg harvesting guidance).

## Known limits

- No EPUB / PDF / accounts / sync / AI.
- Live catalog depends on Gutendex availability (Cloudflare may challenge some networks). A bundled **starter catalog** (10 popular titles) is shown when Gutendex fails.
- Some Gutendex entries lack a non-zip plain-text format and are filtered out; downloads also try `gutenberg.org/cache/epub/{id}/pg{id}.txt`.
- HTTP-only mirrors may fail under default App Transport Security (HTTPS preferred).
- Line engine uses TextKit 1 layout ranges for stable offsets; TextKit 2 is a later upgrade.
- Very large books load fully into memory for MVP (chunked layout is future work).
- App icon slot is empty (placeholder asset catalog); add a 1024×1024 icon before App Store.
- This Linux CI image cannot compile/run iOS targets — open the project on a Mac with Xcode.

## Layout in this repo

This package lives under `AppleDev879/blink` because creating a dedicated GitHub repo from this environment was not permitted. The Blink macOS app is unchanged; open `LineScroll/LineScroll.xcodeproj`, not `Blink.xcodeproj`, for this MVP.
