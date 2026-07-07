# Universal Links

This document is a template only. Do not deploy anything from this repository until placeholders are replaced, server behavior is validated, and the signed iOS build contains the matching Associated Domains entitlement.

Apple references: [Supporting associated domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains), [Associated Domains Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.associated-domains), [applinks object](https://developer.apple.com/documentation/bundleresources/applinks), [Debugging universal links](https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links).

## Required Identifiers

- Apple Team ID: `<TEAM_ID>`, the production signing team's 10-character identifier from Apple Developer.
- Bundle ID: `com.app.slivki` unless the App Store identity changes.
- AASA app id string: `<TEAM_ID>.com.app.slivki`.
- Associated Domains entitlement in the iOS target:

```text
applinks:slivki-shop.ru
```

The Team ID, bundle id, entitlement domain, and AASA `appIDs` value must all describe the same signed app. A mismatch usually makes Universal Links silently fall back to the web.

## Server Path

Serve the Apple App Site Association file at this exact HTTPS path:

```text
https://slivki-shop.ru/.well-known/apple-app-site-association
```

Do not add a `.json` extension to the deployed filename. A root fallback at `https://slivki-shop.ru/apple-app-site-association` may be kept for compatibility, but the release checklist should treat the `/.well-known/apple-app-site-association` URL as required.

## Link Paths

Keep Universal Link paths aligned with public website URLs, not `/api/mobile/v1` API routes.

- Product links: `https://slivki-shop.ru/shop/.../<product-id-or-slug>.html`
  - Current app router handles `/shop/*` URLs ending in `.html`.
  - The router uses the last path component without `.html` as the product identifier, while the current mobile API product detail endpoint expects a numeric id. Do not add `/shop/*` to the deployed AASA file until the API supports slug lookup or public product URLs include a numeric id.
- Category links: preferred templates are `https://slivki-shop.ru/catalog/<category-id-or-slug>` or `https://slivki-shop.ru/category/<category-id-or-slug>`.
  - Native category screens exist.
  - Current app router parses these URL shapes and uses the path id/slug as the native category id. Confirm live website category ids/slugs match the mobile API `category_id` contract before release.
- Search links: `https://slivki-shop.ru/search?q=<query>`
  - Current app router handles `/search` when the `q` query item is present.
- Legal links already routed by the app: `https://slivki-shop.ru/pages/rules.html` and `https://slivki-shop.ru/pages/agreement.html`.

## AASA Template

Use [apple-app-site-association.template.json](./apple-app-site-association.template.json) as the starting point. Before deployment:

- Replace `TEAM_ID` with the production Apple Team ID.
- Replace `BUNDLE_ID` with `com.app.slivki` unless the final bundle id changes.
- Add a `/shop/*` component only after product slug Universal Links open a real native product detail screen.
- Remove category components if real website category ids/slugs do not match the mobile API category filter used by the submitted app.
- Remove any path that does not open a useful native destination in the submitted build.

## Server Requirements

- Return HTTP 200.
- Do not redirect.
- Do not require cookies, JavaScript, user-agent checks, geo checks, or authentication.
- Serve over HTTPS with a valid certificate.
- Use a content type accepted by Apple, normally `application/json` or `application/pkcs7-mime`.
- Keep the file valid JSON and comfortably under Apple's AASA size limit.
- Make caching intentional; remember that iOS and Apple's associated domains service may not fetch changes immediately.

## Validation Steps

1. Validate the local template as JSON before handoff.

```sh
python -m json.tool Docs/Release/apple-app-site-association.template.json
```

2. After server deployment by the web team, verify the required URL.

```sh
curl -i https://slivki-shop.ru/.well-known/apple-app-site-association
```

Expected server result:

- `HTTP/2 200` or `HTTP/1.1 200`.
- No `3xx` redirect.
- Content type is JSON or pkcs7.
- Body contains `<TEAM_ID>.com.app.slivki`.
- Body contains only paths supported by the submitted app.

3. Verify the signed build.

- Inspect the app entitlements and confirm `applinks:slivki-shop.ru` is present.
- Install a fresh build after AASA is available.
- Open search, legal, and any enabled category/product links from Notes, Messages, or Mail on a real device.
- Confirm unsupported links either open the website or route to a safe in-app destination.
- Capture device Console logs filtered around `swcd`/associated domains if a link fails.

4. Regression-test these sample links after placeholders and ids are real:

```text
https://slivki-shop.ru/search?q=молоко
https://slivki-shop.ru/catalog/13730
https://slivki-shop.ru/pages/rules.html
```
