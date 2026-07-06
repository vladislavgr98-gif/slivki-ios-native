# TestFlight Checklist

Use this checklist before internal testing, external TestFlight review, and App Store review handoff.

## Xcode And Signing

- Open the native iOS project in Xcode on a Mac with the correct Apple Developer team selected.
- Bundle ID: `com.app.slivki`.
- Confirm app display name, icon set, launch screen, version, and build number.
- Confirm Release configuration uses production API hosts and production APNs environment for App Store/TestFlight builds.
- Archive with Xcode Organizer and validate the archive before upload.
- Upload dSYM files automatically through Xcode or CI.

## Backend Readiness

- Production mobile API is live over HTTPS.
- `/bootstrap`, catalog, product detail, cart, login, orders, and push token endpoints return stable JSON.
- Demo account works without SMS delivery dependency, or the review notes explain the fixed code flow.
- Test products and order creation are safe for review use and do not create real paid fulfillment without clear controls.
- Backend rate limits and bot protections allow Apple review traffic.

## TestFlight Metadata

- What to Test explains the critical flows: city/bootstrap, catalog browse, product detail, cart update, login, order creation, order history, push permission/token registration.
- Beta App Description matches the native app behavior and does not imply WebView-only functionality.
- Contact email and phone are monitored during review.
- Screenshots and metadata match the submitted build.

## Device Smoke Test

- Fresh install launches without cached auth.
- Returning install preserves cart/auth state as expected.
- App works on small and large iPhones.
- Dark Mode and Dynamic Type do not hide critical controls.
- Offline and slow network states show useful error and retry UI.
- Push permission request appears only at an intentional moment.

## Submission Gate

- No debug menus, staging labels, mock data, or private URLs are visible in release builds.
- No crashes in a clean install smoke test.
- Privacy answers match the app behavior and third-party SDKs.
- Universal Links are either fully configured or not advertised in metadata until working.
