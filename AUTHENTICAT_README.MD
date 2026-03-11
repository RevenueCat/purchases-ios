# IAM Authentication — RevenueCat iOS SDK

This document describes the Identity and Access Management (IAM) authentication mode added to the RevenueCat iOS SDK. IAM mode replaces the legacy API-key-per-request model with a token-based session, enabling server-side identity providers (OIDC, Google, Apple, anonymous) to authenticate users.

---

## Overview

In standard mode, the SDK sends your RevenueCat API key as the `Authorization` header on every request. In IAM mode:

1. You configure the SDK with `iamEnabled: true`.
2. Before using the SDK, your app calls `initAnonymous()` or `loginUser(with:)` to exchange credentials for an **access token** and a **refresh token**.
3. All subsequent SDK requests use `Bearer <access_token>` instead of the API key.
4. When a request receives a `401 Unauthorized` response, the SDK transparently refreshes the token and retries the request once — your app code never sees the 401.
5. User identity is carried by the token, so customer-facing URLs change from `/v1/subscribers/<app_user_id>/...` to `/v1/customer/...`.

---

## Configuration

Enable IAM mode when configuring the `Purchases` singleton, using the `with(iamEnabled:)` builder method:

```swift
// AppDelegate.swift / App.swift
import RevenueCat

let configuration = Configuration.builder(withAPIKey: "YOUR_REVENUECAT_API_KEY")
    .with(iamEnabled: true)   // <-- opt in to IAM mode
    .build()

Purchases.configure(with: configuration)
```

> **Important:** Once `iamEnabled` is `true`, you **must** call `initAnonymous()` or `loginUser(with:)` before making any other SDK call. If you skip this step, every SDK operation will fail with a `configurationError` telling you to establish a session first.

---

## Establishing a Session

### Anonymous session

Use this when you want to interact with the SDK without tying the user to an external identity provider. You can optionally pass a reference string for your own tracking.

**Swift async/await:**
```swift
do {
    try await Purchases.shared.initAnonymous()
    // SDK is ready — fetch offerings, restore purchases, etc.
} catch {
    print("Failed to initialize anonymous session: \(error)")
}
```

**Completion handler (including Objective-C):**
```swift
Purchases.shared.initAnonymous { error in
    if let error {
        print("Failed: \(error)")
        return
    }
    // SDK is ready
}
```

**Objective-C:**
```objc
[[RCPurchases sharedPurchases] initAnonymousWithCompletion:^(NSError * _Nullable error) {
    if (error) {
        NSLog(@"Failed: %@", error);
        return;
    }
    // SDK is ready
}];
```

### Authenticated session

Use `loginUser(with:)` when you have a real user identity from an external provider.

#### OIDC

```swift
// Obtain an ID token from your OIDC provider
let idToken = "eyJhbGci..."

do {
    try await Purchases.shared.loginUser(with: .oidc(idToken: idToken))
} catch {
    print("OIDC login failed: \(error)")
}
```

#### Google Sign-In

```swift
// Obtain an ID token from Google Sign-In SDK
let googleIDToken = "eyJhbGci..."

try await Purchases.shared.loginUser(with: .google(idToken: googleIDToken))
```

#### Sign in with Apple

```swift
import AuthenticationServices

// Inside ASAuthorizationControllerDelegate:
func authorizationController(controller: ASAuthorizationController,
                              didCompleteWithAuthorization authorization: ASAuthorization) {
    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
          let identityTokenData = credential.identityToken,
          let identityToken = String(data: identityTokenData, encoding: .utf8) else { return }

    Task {
        try await Purchases.shared.loginUser(with: .apple(idToken: identityToken))
    }
}
```

#### Completion handler variants

All `loginUser` overloads also have a callback form:

```swift
Purchases.shared.loginUser(with: .google(idToken: googleIDToken)) { error in
    if let error {
        print("Login failed: \(error)")
    }
}
```

---

## Login Methods Reference

`IAMLoginMethod` is a public struct with static factory methods:

| Factory | When to use |
|---|---|
| `.anonymous(reference: String? = nil)` | No external identity; optional opaque reference string |
| `.oidc(idToken: String)` | Any OIDC-compliant provider |
| `.google(idToken: String)` | Google Sign-In |
| `.apple(idToken: String)` | Sign in with Apple |

---

## How It Works Internally

### Authentication endpoints

IAM uses two dedicated endpoints, both authenticated with the API key (not the user token):

| Endpoint | Purpose |
|---|---|
| `POST https://api.revenuecat.com/auth/login` | Exchange credentials for access + refresh + ID tokens |
| `POST https://api.revenuecat.com/auth/token` | Refresh an expired access token using the refresh token |

### Customer endpoints

In IAM mode, the SDK routes customer requests to `/v1/customer/...` instead of the legacy `/v1/subscribers/<app_user_id>/...` paths. User identity is resolved server-side from the Bearer token.

| Operation | IAM path |
|---|---|
| Get customer info | `GET /v1/customer` |
| Get offerings | `GET /v1/customer/offerings` |
| Intro eligibility | `POST /v1/customer/intro_eligibility` |
| Subscriber attributes | `POST /v1/customer/attributes` |
| Attribution data | `POST /v1/customer/attribution` |
| AdServices token | `POST /v1/customer/adservices_attribution` |
| Health report | `GET /v1/customer/health_report` |
| Customer Center config | `GET /v1/customer/customercenter` |
| Restore behavior check | `POST /v1/customer/restore_eligibility` |

### Token lifecycle

```
App calls initAnonymous() / loginUser(with:)
         │
         ▼
POST /auth/login  ──(API key)──►  { access_token, refresh_token, id_token }
         │
         ▼
Tokens stored in IAMSessionManager (in-memory, thread-safe)
         │
         ▼
All SDK requests use  Authorization: Bearer <access_token>
         │
    401 received?
         │  Yes
         ▼
POST /auth/token  ──(API key + refresh_token)──►  new { access_token, ... }
         │
         ▼
Original request retried once with new token
         │
    Still 401?  ──► Error forwarded to caller
```

### Thread safety

`IAMSessionManager` uses a `Lock` for all state mutations. Concurrent 401 responses that trigger a refresh are **deduplicated**: only one `POST /auth/token` call is made, and all waiting requests are resumed once it completes. The token refresh call uses `URLSession.shared` directly (bypassing the SDK's serial request queue) to prevent deadlocks.

---

## Error Handling

| Scenario | Error code |
|---|---|
| SDK call made before session is established | `ErrorCode.configurationError` with message "No IAM session established. Call `initAnonymous()` or `loginUser(with:)` before using the SDK." |
| IAM is not enabled but `initAnonymous()`/`loginUser()` is called | `ErrorCode.configurationError` with message "IAM is not enabled." |
| Login credentials rejected by server | `ErrorCode.networkError` (4xx from `/auth/login`) |
| Token refresh fails and original request returns 401 | `ErrorCode.networkError` (401) forwarded to caller |

---

## Full Integration Example

```swift
import RevenueCat
import SwiftUI

@main
struct MyApp: App {

    init() {
        let config = Configuration.builder(withAPIKey: "rcPublicKey_...")
            .with(iamEnabled: true)
            .build()
        Purchases.configure(with: config)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// In your root view or app coordinator:
struct ContentView: View {

    @State private var isReady = false
    @State private var error: Error?

    var body: some View {
        Group {
            if isReady {
                MainView()
            } else if let error {
                ErrorView(error: error)
            } else {
                ProgressView("Connecting...")
            }
        }
        .task { await setupIAM() }
    }

    private func setupIAM() async {
        do {
            // Replace with loginUser(with: .apple(...)) for authenticated users
            try await Purchases.shared.initAnonymous()
            isReady = true
        } catch {
            self.error = error
        }
    }
}
```

---

## Minimum Requirements

IAM mode requires the same minimum deployment targets as the rest of the SDK:

| Platform | Minimum |
|---|---|
| iOS | 13.0 |
| macOS | 10.15 |
| tvOS | 13.0 |
| watchOS | 6.2 |
| visionOS | 1.0 |

---

## Frequently Asked Questions

**Can I mix IAM mode and the legacy mode?**
No. IAM mode is set once at configuration time. All SDK requests in a given session either use IAM or not.

**Is the access token persisted across app launches?**
No. The current implementation stores tokens in memory only. You must call `initAnonymous()` or `loginUser(with:)` again after each cold launch.

**What happens if the refresh token itself expires?**
The SDK forwards the 401 to your completion handler / async throw. Your app should present a re-authentication UI and call `loginUser(with:)` again.

**Does IAM mode work with Custom Entitlements Computation?**
IAM mode is not available when the SDK is built with `ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION`. The `initAnonymous()` and `loginUser(with:)` methods are excluded from that build target.
