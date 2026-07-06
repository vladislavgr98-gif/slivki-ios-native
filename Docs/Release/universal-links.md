# Universal Links

Universal Links should route public `slivki-shop.ru` product and legal links into the native app when the same destination exists in the app. Keep the AASA paths aligned with existing website URLs, not with the future mobile API paths.

## Associated Domains

Add this Associated Domains entitlement to the iOS target:

```text
applinks:slivki-shop.ru
```

## AASA File

Serve the Apple App Site Association file from one of these HTTPS URLs:

- `https://slivki-shop.ru/.well-known/apple-app-site-association`
- `https://slivki-shop.ru/apple-app-site-association`

Template:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appIDs": ["TEAMID.com.app.slivki"],
        "components": [
          { "/": "/shop/*", "comment": "Product and shop links" },
          { "/": "/pages/rules.html", "comment": "Rules page" },
          { "/": "/pages/agreement.html", "comment": "Agreement page" }
        ]
      }
    ]
  }
}
```

Replace `TEAMID` with the Apple Developer Team ID for the production signing team.

## Server Requirements

- Return HTTP 200.
- Do not redirect.
- Do not require cookies, user agent checks, or auth.
- Serve as `application/json`, `application/pkcs7-mime`, or another Apple-accepted JSON/pkcs7 content type.
- Keep the file under Apple's size limit and valid JSON.

## Verification

```sh
curl -i https://slivki-shop.ru/.well-known/apple-app-site-association
curl -i https://slivki-shop.ru/apple-app-site-association
```

Expected result:

- `HTTP/2 200` or `HTTP/1.1 200`.
- No `3xx` redirect.
- Content type is JSON or pkcs7.
- Body contains `TEAMID.com.app.slivki`.

After installation on a real device, open a matching `https://slivki-shop.ru/shop/...html` link from Notes, Messages, or Safari and confirm iOS opens Slivki instead of only Safari.
