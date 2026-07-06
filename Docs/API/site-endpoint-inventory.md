# Site Endpoint Inventory

This document records site facts useful for the native Slivki iOS MVP. The current slivki-shop.ru website is a visual and product reference only. The iOS app must consume a documented JSON backend API and must not scrape, parse, or depend on HTML from the website.

## Known Facts

- Mobile promo/reference page: `https://slivki-shop.ru/pages/mobil.html`.
- iOS bundle identifier for the native app: `com.app.slivki`.
- No `apple-app-site-association` file was found for `slivki-shop.ru`; Universal Links are not ready until AASA is deployed.
- Android `assetlinks.json` exists or is expected separately, but it needs a separate Android-focused fix and is outside this iOS documentation scope.
- The native app is not a WebView wrapper. Site routes, markup, CSS classes, and client-side scripts are not API contracts.

## Mobile API Boundary

The app should use `Docs/API/mobile-v1.openapi.yaml` as the MVP contract. Backend responses should be stable JSON objects for app screens, carts, auth, orders, push token registration, and bootstrap metadata.

Do not implement app behavior that depends on:

- HTML page structure.
- Product data embedded in scripts.
- Unversioned AJAX endpoints discovered from browser traffic.
- Query parameters or cookies that only exist for the web storefront.
- Web-only authentication or checkout state.

## Endpoint Candidates For Backend Alignment

The MVP requires backend-owned JSON endpoints:

- `GET /api/mobile/v1/bootstrap`
- `GET /api/mobile/v1/catalog`
- `GET /api/mobile/v1/products`
- `GET /api/mobile/v1/products/{id}`
- `GET /api/mobile/v1/cart`
- `PUT /api/mobile/v1/cart`
- `POST /api/mobile/v1/auth/login`
- `GET /api/mobile/v1/orders`
- `POST /api/mobile/v1/orders`
- `POST /api/mobile/v1/push-token`

## Release Risks

- Universal Links will fail App Review deep-link testing until AASA is served from `https://slivki-shop.ru/.well-known/apple-app-site-association` or `https://slivki-shop.ru/apple-app-site-association`.
- Backend must be live and reachable from Apple review networks before TestFlight external review or App Review submission.
- Demo account credentials must be valid against production or review backend.
