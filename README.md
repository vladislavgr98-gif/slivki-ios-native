# Slivki iOS Native

[![CI](https://github.com/vladislavgr98-gif/slivki-ios-native/actions/workflows/ci.yml/badge.svg)](https://github.com/vladislavgr98-gif/slivki-ios-native/actions/workflows/ci.yml)

Native SwiftUI customer app for `slivki-shop.ru`.

The mobile website is used as a visual and product reference only. Core shopping
flows should be native: home, catalog, search, product detail, cart, checkout,
profile, orders, push notifications, and Universal Links. The current app is a
native SwiftUI starter, not a hybrid WebView wrapper.

## Current State

- This repository is a Windows-created native SwiftUI starter scaffold.
- `Package.swift` lets the shared Swift code and tests run on macOS and GitHub Actions.
- Home, catalog, search, product detail, cart, and checkout draft are wired as native SwiftUI screens.
- Read-only catalog/product data is connected to `https://slivki-shop.ru/api/mobile/v1`.
- A real app target, signing, entitlements, Simulator runs, archives, and
  TestFlight uploads must be completed on a Mac with Xcode.
- Auth, server-backed cart, order creation/history, push registration, and final
  Universal Links deployment are planned next phases.

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

1. Create the Xcode app target on Mac.
2. Wire signing and Associated Domains.
3. Run `swift test` and the GitHub Actions CI workflow on macOS.
4. Add safe backend support for auth, cart sync, and order creation.
5. Run TestFlight before touching App Store production metadata.
