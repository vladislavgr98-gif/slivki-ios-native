# Screenshots Plan

Capture these after the app can run in Xcode Simulator or on a real device. Use the same build, data mode, locale, and feature set that will be submitted to App Store Connect.

## Device Sizes

- Primary iPhone set: 6.9-inch display, portrait, using an available simulator such as iPhone 17 Pro Max, iPhone 16 Pro Max, iPhone 16 Plus, iPhone 15 Pro Max, or iPhone 15 Plus.
- Accepted 6.9-inch portrait sizes include `1260 x 2736`, `1290 x 2796`, and `1320 x 2868`.
- Fallback iPhone set: 6.5-inch display, portrait, only if 6.9-inch screenshots are not provided. Accepted portrait sizes include `1284 x 2778` and `1242 x 2688`.
- Optional QA-only set: one small iPhone simulator to verify text, tabs, buttons, and product cards do not clip.

Apple reference: [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).

## Capture Setup

- Locale: Russian.
- Appearance: light mode for the primary App Store set; capture dark mode separately only for QA.
- Status bar: clean time, full battery, stable network indicator.
- Data: approved live review data or approved fixtures with realistic product names, prices, images, and availability.
- Avoid screenshots that show staging banners, debug labels, placeholder API messages, private URLs, personal addresses, or real customer data.
- Use PNG or JPEG/JPG. App Store Connect accepts 1-10 screenshots per device class and locale.

## Required Screen List

1. Home
   - Screen: main tab with store name/address, categories, and popular products.
   - Caption: `Категории и популярные товары`
   - Notes: wait for images to load; avoid loading/error banner unless the release intentionally documents offline behavior.

2. Catalog
   - Screen: catalog tab with category grid.
   - Caption: `Весь каталог под рукой`
   - Notes: choose a state with several recognizable categories.

3. Category Product List
   - Screen: product list after opening a category.
   - Caption: `Выбирайте нужную категорию`
   - Notes: show product cards with prices and availability; avoid empty categories for App Store screenshots.

4. Search
   - Screen: search results for a common grocery query.
   - Caption: `Быстрый поиск по товарам`
   - Notes: use a query that returns multiple relevant products.

5. Product Detail
   - Screen: product detail with image, title, price, description, availability, quantity stepper, and add-to-cart button.
   - Caption: `Цена, наличие и описание товара`
   - Notes: use an available product with a clean image.

6. Cart
   - Screen: cart with at least two products, quantity controls, and total.
   - Caption: `Соберите корзину перед заказом`
   - Notes: verify totals are realistic and no backend error is visible.

7. Checkout Draft
   - Screen: checkout form with contact, city/address, and order total.
   - Caption: `Проверьте данные перед оформлением`
   - Notes: capture for TestFlight only while checkout is a draft. Do not use this in App Store screenshots until submission creates a clear, safe, supported order flow.

8. Profile And Legal
   - Screen: profile tab with login state and legal links, or a legal page if review needs proof.
   - Caption: `Профиль и документы магазина`
   - Notes: avoid claiming account features if login remains a placeholder.

## QA Before Upload

- Every caption is Russian and matches the screen.
- No screenshot claims delivery, payment, loyalty, order tracking, or push notifications unless the submitted build supports them.
- Text is readable at App Store thumbnail size.
- Product names, prices, and availability look consistent across screenshots.
- Screenshots match the App Store metadata and TestFlight What to Test text.
