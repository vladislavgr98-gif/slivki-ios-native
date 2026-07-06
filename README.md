# Slivki iOS Native

Native SwiftUI customer app for `slivki-shop.ru`.

The mobile website is used as a visual and product reference only. Core shopping
flows should be native: home, catalog, search, product detail, cart, checkout,
profile, orders, push notifications, and Universal Links.

## Current State

- This repository is a Windows-created starter scaffold.
- `Package.swift` lets the shared Swift code and tests be opened on macOS.
- A real app target, signing, entitlements, Simulator runs, archives, and
  TestFlight uploads must be completed on a Mac with Xcode.
- Live screens are intentionally fixture-first until the website exposes stable
  JSON endpoints under `/api/mobile/v1`.

## Suggested Mac Setup

```bash
git clone <repo-url> slivki-ios-native
cd slivki-ios-native
open Package.swift
```

After the shared code is healthy, create an Xcode iOS app target named `Slivki`
and include the `Slivki/` source folder. Keep bundle id aligned with the current
App Store identity unless ownership changes:

```text
com.app.slivki
```

## First Milestones

1. Finish and approve the mobile API contract in `Docs/API/mobile-v1.openapi.yaml`.
2. Create the Xcode app target on Mac.
3. Wire signing and Associated Domains.
4. Replace fixtures with live `/api/mobile/v1` data screen by screen.
5. Run TestFlight before touching App Store production metadata.
