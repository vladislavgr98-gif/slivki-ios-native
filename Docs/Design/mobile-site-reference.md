# Mobile Site Reference

The mobile website is the product and visual reference for the native iOS app.
It is not the runtime surface of the app.

## Reference URLs

- Home and product discovery: `https://slivki-shop.ru/shop`
- Mobile app promo page: `https://slivki-shop.ru/pages/mobil.html`
- Product pages: `https://slivki-shop.ru/shop/...html`
- Legal pages: `https://slivki-shop.ru/pages/rules.html` and `https://slivki-shop.ru/pages/agreement.html`

## Native Mapping

| Website concept | Native iOS screen |
| --- | --- |
| Mobile header, city, search | `HomeView` header and search entry |
| Category shortcuts | `CategoryTileView` and `CatalogView` |
| Product cards | `ProductCardView` |
| Product detail page | `ProductDetailView` |
| Cart page | `CartView` |
| Profile/login area | `LoginView` — call-first auth (phone → free call → email fallback → register) |
| Rules/agreement pages | `LegalWebView` fallback only |

## UI Direction

- Keep the green Slivki brand color as the primary action color.
- Prefer compact, scannable shopping UI over landing-page composition.
- Use native tab navigation for repeated shopping flows.
- Use native search, quantity controls, forms, loading states, and error states.
- Use `WKWebView` only for legal/static pages while native replacements are not ready.

## Captured Reference Screenshots

Reference screenshots captured with a mobile browser viewport:

- `Docs/Design/screenshots/home-mobile.png`
- `Docs/Design/screenshots/catalog-mobile.png`
- `Docs/Design/screenshots/product-mobile.png`
- `Docs/Design/screenshots/cart-mobile.png`
- `Docs/Design/screenshots/profile-mobile.png`
- `Docs/Design/screenshots/search-mobile.png`

Use these files for parity checks before each UI pass.
