# Device Matrix

Use this matrix for MVP regression and release candidate testing. Prefer real devices for push, Universal Links, keyboard, camera/photo permissions if added, and Apple review confidence.

## Primary Devices

| Device | OS | Priority | Coverage |
| --- | --- | --- | --- |
| iPhone SE 3rd gen | Latest supported iOS | P0 | Small screen, compact layout, keyboard overlap. |
| iPhone 13 or 14 | Latest supported iOS | P0 | Common baseline device. |
| iPhone 15 or 16 Pro | Latest iOS | P0 | Current hardware, Dynamic Island, performance. |
| iPhone 15 or 16 Pro Max | Latest iOS | P1 | Large screen, one-handed reach, long lists. |
| iPad running iPhone app compatibility mode | Latest iPadOS | P2 | Basic launch/readability if iPhone-only. |

## System States

| State | Expected Result |
| --- | --- |
| Fresh install | App shows bootstrap/catalog without cached user data. |
| Logged out | Catalog and product detail work; auth-only actions ask for login. |
| Logged in | Cart, order creation, and order history use the account. |
| Offline launch | App shows cached state if available and a retry path. |
| Slow network | Loading states remain stable and duplicate submits are prevented. |
| API error | User sees recoverable error, not a blank screen. |
| Empty catalog/search | Empty states are clear and do not look broken. |
| Out-of-stock product | Add-to-cart is blocked or clearly explained. |
| Cart price change | Cart refresh explains changed totals before order submit. |
| Push denied | App remains fully usable. |
| Dark Mode | Text, images, buttons, and status labels remain readable. |
| Large Dynamic Type | Critical controls are reachable without overlap. |
| Low Power Mode | No required animation or background behavior breaks the flow. |

## Network And Backend

- Test on Wi-Fi and cellular.
- Test with backend maintenance/error responses.
- Test auth token expiry and refresh or forced logout behavior.
- Test duplicate taps on cart update and order submit.
- Test image loading failures and placeholders.
