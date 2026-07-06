# Regression Checklist

Run this checklist before TestFlight uploads and App Review submission.

## Bootstrap And Navigation

- App launches from a clean install.
- `/bootstrap` loads selected city, categories, banners, user state, and cart.
- City selection or city state is reflected in catalog/product responses.
- Tab or root navigation preserves expected state after switching screens.
- Pull-to-refresh or retry does not duplicate items.

## Catalog And Products

- Catalog categories load and nested categories render correctly.
- Product list supports paging without duplicates or missing rows.
- Search returns matching results and a useful empty state.
- Sorting, if enabled, matches backend order.
- Product detail opens from list, banner, Universal Link, and cart item.
- Product images load with placeholders and failure handling.
- Prices, old prices, discounts, availability, and currency are formatted consistently.

## Cart

- Add product to cart.
- Increase and decrease quantity.
- Remove item by setting quantity to zero or tapping remove.
- Cart persists across app restart for the same user/session.
- Cart handles out-of-stock items.
- Cart handles backend price changes with a visible explanation.
- Duplicate taps do not create incorrect quantities.

## Auth

- Login with demo phone/code succeeds.
- Invalid code shows a clear error.
- Expired session is handled without data corruption.
- Logout or account reset, if present, clears private state.
- Logged-out users are prompted only when entering auth-required flows.

## Orders

- Create order from a valid cart.
- Required fields validate before submit.
- Backend validation errors are visible and actionable.
- Order confirmation shows order number/status.
- Order history loads through `GET /orders`.
- Order list pagination works if the account has enough history.
- Test orders are marked or handled so they do not trigger unwanted real fulfillment.

## Push Notifications

- App asks for push permission at the intended moment.
- Denying permission does not block shopping.
- APNs token registration calls `POST /push-token` after permission/token availability.
- Reinstall or token refresh updates backend token state.

## Universal Links

- `applinks:slivki-shop.ru` entitlement is present in the signed build.
- AASA returns 200 without redirect.
- Product and catalog links open matching app screens on a real device.
- Unsupported links fall back to Safari or a safe in-app route.

## Release Sanity

- Release build has no staging labels, debug menus, or mock data.
- App metadata and screenshots match current UI.
- Privacy prompts and App Store privacy answers match actual behavior.
- Clean install smoke test passes on at least one small and one large iPhone.
