# App Review Notes

Use this as the source for App Store Connect review notes. Keep the final text concise and update credentials before submission.

## Review Access

- App type: native SwiftUI iOS shopping app for slivki-shop.ru.
- Bundle ID: `com.app.slivki`.
- Demo account phone: `+7 XXX XXX-XX-XX`.
- Demo code or password: `XXXX`.
- If login normally uses SMS, the demo account must accept the fixed review code above.

## Suggested Review Notes

```text
Slivki is a native SwiftUI iOS app for browsing catalog products, managing a cart, signing in, placing an order, viewing order history, and registering for push notifications.

Please use the demo account:
Phone: +7 XXX XXX-XX-XX
Code: XXXX

The backend is live for review. Test orders created from this account are for review only and will not require real payment or fulfillment.

Universal Links use applinks:slivki-shop.ru when the AASA file is live. If a specific link does not open the app during review, the same product and catalog content is available through in-app navigation.
```

## Apple Review Risks To Clear

- Demo account works from a clean install.
- Backend is production-like and reachable without VPN or IP allowlist.
- Any payment, delivery, or order side effect is safe and explained.
- App metadata and screenshots show the submitted build, not the website.
- Privacy labels match collected data, account behavior, analytics, push, and crash reporting.
- Push notifications are optional and permission timing is user-driven.
- No hidden WebView dependency is required for core shopping flows.

## Before Submit

- Replace placeholder demo phone/code.
- Confirm support contact is monitored.
- Confirm review notes mention any temporary limitations honestly.
- Confirm screenshots match current UI, city, prices, and product names.
