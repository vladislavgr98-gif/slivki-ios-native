# TestFlight Checklist

Use this checklist before internal testing, external TestFlight review, and App Store review handoff. The current repository is a native SwiftUI starter with fixture fallback; do not describe unfinished backend, auth, checkout, orders, push, or Universal Links work as production-ready until the submitted build proves it.

## Prerequisites

- Mac with current Xcode installed and access to the Apple Developer account.
- Xcode iOS app target exists and includes the `Slivki/` source folder.
- Bundle ID is confirmed: `com.app.slivki`.
- Correct Apple Team is selected for signing.
- App display name, app icon, launch screen, version, and build number are set.
- Release configuration points to the approved production or review backend.
- Associated Domains entitlement is present only if AASA is live and validated: `applinks:slivki-shop.ru`.
- Privacy manifest, App Store privacy answers, and privacy policy URL match actual app behavior.
- No staging labels, debug menus, private API hosts, or unapproved fixture-only messaging are visible in the release build.

## Backend Readiness

- `GET /api/mobile/v1/bootstrap` returns site name, city/address, categories, and featured products.
- `GET /api/mobile/v1/catalog` returns categories with stable ids, titles, slugs, and images.
- `GET /api/mobile/v1/products` supports category and search query parameters used by the app.
- `GET /api/mobile/v1/products/{id}` returns product detail fields shown in the app.
- Cart, login, checkout/order, orders, and push token endpoints are either implemented and tested or excluded from external claims.
- Review/demo data is safe: test products and test orders do not trigger unwanted real payment, delivery, or fulfillment.
- Backend rate limits, bot protection, WAF rules, and geofencing allow Apple review traffic.

## Build Upload

- Run unit tests for shared Swift code.
- Build a clean Release archive in Xcode Organizer.
- Validate the archive before upload.
- Upload the build to App Store Connect with dSYM files.
- Confirm processing completes without missing compliance, encryption, privacy, or symbol warnings.
- Attach the build to the TestFlight group only after the local smoke test passes.

## Internal Testing

- Start with a small internal group that can report quickly.
- Test clean install and upgrade over the previous build if one exists.
- Confirm launch, tab navigation, loading, retry, and empty/error states.
- Verify fixture fallback does not hide backend failures in a release candidate without an explicit decision.
- Capture screenshots of any visual regression before filing issues.
- Do not move to external testing while checkout/login/order screens are confusingly present but nonfunctional.

## External Testing

- Beta App Description matches the submitted build.
- What to Test lists only supported flows:
  - Browse home categories and featured products.
  - Open catalog categories and product lists.
  - Search by product name or category.
  - Open product detail from home, category, search, and Universal Link if enabled.
  - Add available products to cart and update quantities.
  - Open checkout draft only if the beta goal is to review the form; otherwise mark order submission as out of scope.
  - Open profile and legal pages.
- Provide demo credentials only when login is wired to a stable review backend.
- Explain whether test orders are disabled, simulated, or safe to submit.
- Monitor the contact email and phone listed in TestFlight metadata.

## Test Scenarios

- Home: load site name, city/address, categories, featured products, images, retry state, and offline fallback.
- Catalog: category grid loads; tapping a category opens a product list; empty category state is understandable.
- Search: empty query, matching query, no-results query, retry after network failure, add-to-cart from search results.
- Product detail: image placeholder/failure, price and old price formatting, availability, seller title, quantity stepper, disabled add button for unavailable items.
- Cart: empty cart, add product, increment/decrement quantity, remove by setting quantity to zero, total recalculation.
- Checkout draft: contact fields, phone keyboard, city/address fields, total display, disabled submit for empty cart; confirm submit behavior before external testing.
- Profile/auth: logged-out state, disabled login button when fields are empty, placeholder message if auth is not connected.
- Legal pages: rules and agreement links open the expected pages or fail gracefully.
- Universal Links: product, category, and search links open the expected native screens only after AASA deployment and real URL/id validation.
- Accessibility: Dynamic Type, VoiceOver labels on key controls, color contrast, small-screen layout.
- Network: offline launch, slow catalog response, API error response, image load failure.

## Crash And Log Feedback

- Enable TestFlight crash feedback and screenshot feedback for the beta group.
- Check Xcode Organizer for crashes after every testing wave.
- Ask testers to include steps, screen name, account/test data, device model, iOS version, and approximate time.
- Collect Console logs from a tethered device when a Universal Link, networking, or launch issue cannot be reproduced.
- Ensure logs do not contain passwords, auth tokens, phone numbers, payment details, or private addresses.
- Verify dSYM upload before investigating symbolicated crashes.

## Submission Gate

- No known crash on clean install.
- App metadata, screenshots, privacy answers, and review notes match the exact build.
- Universal Links are either fully configured and tested on a real device or absent from marketing claims.
- Checkout/order behavior is clear and safe for Apple Review.
- TestFlight external review notes include demo access and known limitations.
