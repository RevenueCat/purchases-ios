# Security Review Report: purchases-ios

**Date:** 2026-05-11
**Branch:** `cursor/codebase-security-review-0dcb`
**Scan type:** At-rest codebase review

## Summary

| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 0 |
| Medium | 3 |

---

## Finding 1: Sensitive Data Logged Without OS-Level Redaction

**Severity:** Medium
**Location:** `Sources/LocalReceiptParsing/Helpers/LoggerType.swift:131`
**Verified:** Yes

### Description

All SDK log messages are emitted with `privacy: .public` in the `os.Logger` call, which disables iOS's built-in log redaction. This means sensitive data included in log messages — such as receipt contents, JWS tokens, API response bodies, and subscriber information — is persisted in plaintext in the unified logging system and is never redacted by the OS.

Additionally, the fallback `NSLog` path (for older OS versions) also logs messages without any privacy protection.

### Impact

An attacker or unauthorized party with access to device logs (via sysdiagnose captures, MDM tools, Console.app, device backups, or forensic tools) can extract:
- Full Apple receipt data and JWS transaction tokens (logged at debug level via `PostReceiptDataOperation.printReceiptData()`)
- Raw API response bodies containing CustomerInfo, entitlement data, and subscription details (logged at error level via `NetworkError.decoding()` on any JSON parse failure)
- Signature verification internals in DEBUG builds

### Attack Path

1. App integrates RevenueCat SDK (default configuration).
2. SDK makes API requests; on any JSON decode failure, the full response body is logged at error level with `.public` privacy.
3. Receipt posting (when log level ≤ debug) logs full receipt contents, JWS tokens, and SK2 receipt JSON with `.public` privacy.
4. Logs persist in the iOS unified logging system without OS-level redaction.
5. An attacker captures logs via sysdiagnose, shared diagnostics, MDM, or physical access and extracts sensitive purchase/subscription data.

### Evidence

- `Sources/LocalReceiptParsing/Helpers/LoggerType.swift:131` — All messages logged with `privacy: .public`
- `Sources/Networking/HTTPClient/NetworkError.swift:39-42` — Raw response body logged on decode error
- `Sources/Logging/Strings/NetworkStrings.swift:103-104` — `"Data received: \(dataString)"` template
- `Sources/Networking/Operations/PostReceiptDataOperation.swift:97-100` — Receipt/JWS logged at debug level
- `Sources/LocalReceiptParsing/Helpers/ReceiptStrings.swift:92-100` — Full receipt/JWS/SK2 receipt in log strings

### Remediation

Use `privacy: .private` or `privacy: .sensitive` for log interpolations that may contain user data or sensitive API responses. Consider:

```swift
// Before (current)
.log(level: level.logType, "\(message, privacy: .public)")

// After (recommended)
.log(level: level.logType, "\(message, privacy: .private)")
```

For the decode-error logging path, either redact or truncate the response body, or gate it behind a debug-only flag.

---

## Finding 2: IdentityManager.resetCacheAndSave TOCTOU Causes Attribution Data Retention

**Severity:** Medium
**Location:** `Sources/Identity/IdentityManager.swift:193-197`
**Verified:** Yes

### Description

In `IdentityManager.resetCacheAndSave(newUserID:)`, there is a time-of-check-time-of-use (TOCTOU) bug. Line 194 calls `clearCaches(oldAppUserID: currentAppUserID, andSaveWithNewUserID: newUserID)`, which internally updates `cachedAppUserID` to `newUserID`. Line 195 then calls `clearLatestNetworkAndAdvertisingIdsSent(appUserID: currentAppUserID)`, but `currentAppUserID` now returns the **new** user ID (already updated), not the old one. As a result, the old user's advertising IDs and attribution data are never cleared from UserDefaults.

### Impact

When a user logs out or switches users, the previous user's advertising identifiers and attribution network data persist in UserDefaults. This is a privacy/data retention violation — personal advertising data is not cleaned up during user transitions as intended.

### Attack Path

1. User A logs in and uses the app; attribution data (advertising IDs, network attribution) is cached in UserDefaults keyed to User A's ID.
2. User A logs out; `resetCacheAndSave` is called.
3. `clearCaches` updates `cachedAppUserID` to the new anonymous ID.
4. `clearLatestNetworkAndAdvertisingIdsSent` is called with `currentAppUserID`, which now returns the new ID, not User A's ID.
5. User A's attribution data remains in UserDefaults indefinitely.
6. On a shared or recycled device, this data persists beyond the user's session.

### Evidence

- `Sources/Identity/IdentityManager.swift:193-197` — `resetCacheAndSave` method
- `Sources/Caching/DeviceCache.swift:152-154` — `clearCaches` updates `_cachedAppUserID` to `newUserID`
- `Sources/Identity/IdentityManager.swift:71-77` — `currentAppUserID` reads from `deviceCache.cachedAppUserID`

### Remediation

Capture the old user ID before calling `clearCaches`:

```swift
func resetCacheAndSave(newUserID: String) {
    let oldAppUserID = currentAppUserID
    self.deviceCache.clearCaches(oldAppUserID: oldAppUserID, andSaveWithNewUserID: newUserID)
    self.deviceCache.clearLatestNetworkAndAdvertisingIdsSent(appUserID: oldAppUserID)
    self.backend.clearHTTPClientCaches()
}
```

---

## Finding 3: CachingProductsManager.clearCache() Is a No-Op

**Severity:** Medium
**Location:** `Sources/Purchasing/CachingProductsManager.swift:54-61`
**Verified:** Yes

### Description

`CachingProductsManager.clearCache()` calls `self.productCache.value.removeAll(keepingCapacity: true)`. Because `Atomic<T>.value` getter returns a **copy** of the wrapped value (dictionaries are value types in Swift), `removeAll()` operates on the temporary copy, not the actual stored dictionary. The internal cache is never cleared.

The same bug applies to `self.sk2ProductCache.value.removeAll(keepingCapacity: true)` on line 57.

### Impact

When `clearCache()` is called (e.g., during storefront changes via `handleStorefrontChange()`), stale product data remains in the cache. This could cause the SDK to serve outdated pricing, introductory offer eligibility, or promotional offer data after a storefront change, leading to incorrect purchase flows or pricing displayed to users.

### Attack Path

1. User travels to a different country or changes their App Store region.
2. `handleStorefrontChange()` fires, calling `productsManager.clearCache()`.
3. `clearCache()` silently fails to clear the in-memory product cache.
4. The SDK continues serving stale `StoreProduct` objects with old pricing/currency/eligibility from the previous storefront.
5. User sees incorrect prices or eligibility status until the app is restarted (since the in-memory cache persists).

### Evidence

- `Sources/Purchasing/CachingProductsManager.swift:54-58` — `clearCache()` method
- `Sources/Misc/Concurrency/Atomic.swift:54-56` — `value` getter returns through `withValue { $0 }`, which copies value types
- `Sources/Purchasing/Purchases/PurchasesOrchestrator.swift:1944` — `handleStorefrontChange()` calls `productsManager.clearCache()`

### Remediation

Use `Atomic.modify` to mutate the stored value in-place:

```swift
func clearCache() {
    self.productCache.modify { $0.removeAll(keepingCapacity: true) }
    if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
        self.sk2ProductCache.modify { $0.removeAll(keepingCapacity: true) }
    }
    self.manager.clearCache()
}
```
