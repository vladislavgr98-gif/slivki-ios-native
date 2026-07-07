# App Review Notes

Use this as the source for App Store Connect review notes. Keep the final text concise and update credentials before submission.

## Review Access

- App type: native SwiftUI iOS shopping app for slivki-shop.ru.
- Bundle ID: `com.app.slivki`.
- Demo account phone: `<ONLY_IF_LOGIN_IS_ENABLED>`.
- Demo code or password: `<ONLY_IF_LOGIN_IS_ENABLED>`.
- If login is enabled and normally uses SMS, the demo account must accept a fixed review code that does not depend on Apple receiving SMS.

## Suggested Review Notes

```text
Slivki is a native SwiftUI iOS app for browsing catalog products, searching items, opening product details, and managing a local cart.

The current submitted build uses the live read-only mobile API for catalog/product data. Checkout is a draft form unless the submitted build notes explicitly state that order creation is enabled and safe for review.

If login is enabled in the submitted build, please use the demo account below:
Phone: <DEMO_PHONE>
Code: <DEMO_CODE>

Universal Links use applinks:slivki-shop.ru only when the AASA file is live and validated. If Universal Links are not enabled for this build, the same product and catalog content is available through in-app navigation.
```

## Apple Review Risks To Clear

- Demo account works from a clean install if login is enabled.
- Backend is production-like and reachable without VPN or IP allowlist.
- Any payment, delivery, or order side effect is safe and explained.
- App metadata and screenshots show the submitted build, not the website.
- Privacy labels match collected data, account behavior, analytics, push, and crash reporting.
- Push notifications are optional and permission timing is user-driven if push is enabled.
- No hidden WebView dependency is required for core shopping flows.

## Before Submit

- Replace placeholder demo phone/code.
- Confirm support contact is monitored.
- Confirm review notes mention any temporary limitations honestly.
- Confirm screenshots match current UI, city, prices, and product names.
