# Slivki WebView Hotfix (1.0.1)

Emergency replacement for the App Store `com.app.slivki` WebView shell.

Loads `https://slivki-shop.ru/` and fixes the production navigation bug where back
or edge-swipe could show a false native error screen.

## Fixes

- Ignore `NSURLErrorCancelled` during back / swipe-back navigation
- Ignore WebKit frame-load interruption errors
- Do not show the error overlay when history still has a loaded page
- Reload automatically when the WebKit content process terminates
- Clear WK cache once per marketing version bump

## Open in Xcode

```bash
open /Users/slivki/Documents/Slivki/slivki-ios-webview-hotfix/SlivkiWebHotfix.xcodeproj
```

## Signing

1. Target `SlivkiWebHotfix` → Signing & Capabilities
2. Team = your Apple Developer account
3. Bundle ID must stay `com.app.slivki`
4. Version: `1.0.1` (build `2`)

## App icon

Add the existing store icon to `SlivkiWebHotfix/Assets.xcassets/AppIcon.appiconset`
before App Store upload. You can export it from App Store Connect media or the old IPA.

## Test on Simulator

1. Run scheme `SlivkiWebHotfix`
2. Open a product
3. Swipe back from the left edge
4. Confirm the false error screen does not appear

## Archive and upload

1. Select `Any iOS Device`
2. Product → Archive
3. Distribute App → App Store Connect → Upload
4. In App Store Connect open app **Сливки.**
5. Select build `1.0.1 (2)`
6. Submit for Review

Suggested review note:

```text
Bug fix release for WebView navigation. Back gesture and edge swipe no longer show a false error screen when the store page is still available in history.
```

## Relationship to native app

This hotfix is temporary. Continue `slivki-ios-native` for the full native rewrite and ship it as a later major update.
