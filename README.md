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
- Home, catalog, search, product detail, cart, checkout, profile, orders, and
  favorites are wired as native SwiftUI screens.
- Live catalog/product data, server cart recalculation, order draft submission,
  empty order history, and explicit auth placeholder responses are connected to
  `https://slivki-shop.ru/api/mobile/v1`.
- A real Xcode app target, Associated Domains entitlements, SwiftPM tests, Xcode
  Simulator build, install, and launch have been verified locally.
- Real SMS auth, real fulfillment order creation, push registration, and final
  Universal Links AASA deployment are the remaining backend/release phases.

## Suggested Mac Setup

```bash
git clone <repo-url> slivki-ios-native
cd slivki-ios-native
open Package.swift
```

Open the Xcode project or Swift package on macOS. Keep bundle id aligned with
the current App Store identity unless ownership changes:

```text
com.app.slivki
```

## First Milestones

1. Keep `swift test` and `xcodebuild -project Slivki.xcodeproj -scheme Slivki`
   green before shipping changes.
2. Finish real SMS auth and token issuance in the backend.
3. Promote order drafts to a safe production order flow only after fulfillment
   rules are agreed.
4. Deploy AASA only after the Apple Team ID is known.
5. Run TestFlight before touching App Store production metadata.
