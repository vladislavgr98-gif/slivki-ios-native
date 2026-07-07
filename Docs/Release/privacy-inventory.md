# Privacy Inventory

This inventory supports App Store privacy answers and review notes. Update it whenever SDKs, analytics, payments, auth, or backend logging change.

## Data Types

| Data | Purpose | Linked To User | Notes |
| --- | --- | --- | --- |
| Phone number | Login, account lookup, order contact | Yes | Required for authenticated order flows. |
| Name | Order contact, profile display | Yes | Optional unless backend requires it for delivery. |
| Email | Support or account contact | Yes | Optional for MVP unless added to profile/checkout. |
| Delivery address | Order fulfillment | Yes | Only collected when delivery is supported. |
| Cart contents | Shopping cart and checkout | Yes when logged in | May exist anonymously before login. |
| Order history | Customer support and repeat purchase | Yes | Include only when order history is enabled in the submitted build. |
| Device push token | Push notifications | Yes or device-linked | Include only when APNs registration is enabled; permission must be optional. |
| Crash diagnostics | Stability | Usually device-linked | Depends on Apple/Xcode or crash SDK configuration. |
| Usage analytics | Product analytics | Depends on SDK | Add exact SDK and events before submission. |

## App Store Connect Privacy Answers

- Account creation/login: yes, if login is available in the submitted build.
- Purchases/order data: yes, if the app creates orders or stores order history.
- Contact info: phone number is collected for login/order contact.
- Location: answer yes only if precise or approximate location APIs are used. City selection alone is not device location.
- User content: no, unless reviews, comments, uploads, or support attachments are added.
- Identifiers: answer yes if analytics, push, or backend uses device identifiers beyond APNs token.
- Diagnostics: answer yes if crash or performance diagnostics are collected.
- Tracking: answer yes only if data is linked across apps/websites owned by other companies for advertising or measurement under Apple's ATT definition.

## Release Requirements

- Privacy Policy URL must be live in App Store Connect.
- Permission strings in `Info.plist` must match actual prompts.
- Push notification prompt must not block catalog browsing.
- Do not include third-party SDKs in release builds unless they are reflected in privacy answers.
- Backend logs should avoid storing raw secrets, auth tokens, or full payment details.
