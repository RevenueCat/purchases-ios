# Solar Engine Integration Design

**Date:** 2026-01-05
**Status:** Approved
**Platforms:** iOS, Android

## Overview

Add support for capturing three Solar Engine identifiers in both RevenueCat iOS and Android SDKs:
- `$solarEngineDistinctId`
- `$solarEngineAccountId`
- `$solarEngineVisitorId`

This integration follows the exact same pattern as the existing Airbridge device ID integration.

## Integration Pattern

### Developer Usage

Developers will manually retrieve IDs from Solar Engine SDK and pass them to RevenueCat.

**Android Example:**
```kotlin
// Get IDs from Solar Engine
val distinctId = SolarEngineManager.getInstance().getDistinctId()
val visitorId = SolarEngineManager.getInstance().getVisitorID()
val accountId = SolarEngineManager.getInstance().getAccountID()

// Pass to RevenueCat
Purchases.sharedInstance.setSolarEngineDistinctId(distinctId)
Purchases.sharedInstance.setSolarEngineVisitorId(visitorId)
Purchases.sharedInstance.setSolarEngineAccountId(accountId)
```

**iOS Example:**
```swift
// Get IDs from Solar Engine
let distinctId = SolarEngineSDK.sharedInstance().getDistinctId()
let visitorId = SolarEngineSDK.sharedInstance().visitorID
let accountId = SolarEngineSDK.sharedInstance().accountID

// Pass to RevenueCat
Purchases.shared.attribution.setSolarEngineDistinctId(distinctId)
Purchases.shared.attribution.setSolarEngineVisitorId(visitorId)
Purchases.shared.attribution.setSolarEngineAccountId(accountId)
```

### Key Characteristics

- **Three independent methods:** Each ID can be set separately
- **No automatic fetching:** RevenueCat does not call Solar Engine SDK directly
- **Nullable values:** Passing `nil`/`null` or empty string clears the attribute
- **Device identifier collection:** Automatically triggers collection if enabled (IDFA, IDFV, GPS Ad ID, etc.)
- **Automatic sync:** Attributes sync to backend on next sync cycle

## iOS Implementation

### Files to Modify

**1. `Sources/SubscriberAttributes/ReservedSubscriberAttributes.swift`**
- Add three new enum cases:
  ```swift
  case solarEngineDistinctId = "$solarEngineDistinctId"
  case solarEngineAccountId = "$solarEngineAccountId"
  case solarEngineVisitorId = "$solarEngineVisitorId"
  ```

**2. `Sources/Purchasing/Purchases/Attribution.swift`**
- Add three public methods:
  ```swift
  /**
   * Subscriber attribute associated with the Solar Engine Distinct ID.
   * Recommended for the RevenueCat Solar Engine integration.
   *
   * - Parameter solarEngineDistinctId: Empty String or `nil` will delete the subscriber attribute.
   */
  @objc func setSolarEngineDistinctId(_ solarEngineDistinctId: String?) {
      self.subscriberAttributesManager.setSolarEngineDistinctId(solarEngineDistinctId, appUserID: appUserID)
  }

  @objc func setSolarEngineAccountId(_ solarEngineAccountId: String?) {
      self.subscriberAttributesManager.setSolarEngineAccountId(solarEngineAccountId, appUserID: appUserID)
  }

  @objc func setSolarEngineVisitorId(_ solarEngineVisitorId: String?) {
      self.subscriberAttributesManager.setSolarEngineVisitorId(solarEngineVisitorId, appUserID: appUserID)
  }
  ```

**3. `Sources/SubscriberAttributes/SubscriberAttributesManager.swift`**
- Add three setter methods:
  ```swift
  func setSolarEngineDistinctId(_ solarEngineDistinctId: String?, appUserID: String) {
      setAttributionID(solarEngineDistinctId, forNetworkID: .solarEngineDistinctId, appUserID: appUserID)
  }

  func setSolarEngineAccountId(_ solarEngineAccountId: String?, appUserID: String) {
      setAttributionID(solarEngineAccountId, forNetworkID: .solarEngineAccountId, appUserID: appUserID)
  }

  func setSolarEngineVisitorId(_ solarEngineVisitorId: String?, appUserID: String) {
      setAttributionID(solarEngineVisitorId, forNetworkID: .solarEngineVisitorId, appUserID: appUserID)
  }
  ```

**4. `Tests/UnitTests/SubscriberAttributes/PurchasesSubscriberAttributesTests.swift`**
- Add unit tests:
  ```swift
  func testSetAndClearSolarEngineDistinctId()
  func testSetAndClearSolarEngineAccountId()
  func testSetAndClearSolarEngineVisitorId()
  ```

**5. `Tests/TestingApps/PurchaseTesterSwiftUI/Shared/Views/Customer/SubscriberAttributesView.swift`** (optional)
- Add UI test support for manual testing

### Behavior
- Each method triggers automatic device identifier collection (IDFA, IDFV, IP) if enabled
- Attributes stored locally with sync flag = false
- Backend sync happens automatically via existing `PostSubscriberAttributesOperation`
- No changes needed to networking layer (reuses existing endpoint)

## Android Implementation

### Files to Modify

**1. `purchases/src/main/kotlin/com/revenuecat/purchases/common/subscriberattributes/SpecialSubscriberAttributes.kt`**
- Add to `ReservedSubscriberAttribute` enum:
  ```kotlin
  SOLAR_ENGINE_DISTINCT_ID("\$solarEngineDistinctId"),
  SOLAR_ENGINE_ACCOUNT_ID("\$solarEngineAccountId"),
  SOLAR_ENGINE_VISITOR_ID("\$solarEngineVisitorId"),
  ```

- Add to `SubscriberAttributeKey.AttributionIds`:
  ```kotlin
  object SolarEngineDistinctId : AttributionIds(ReservedSubscriberAttribute.SOLAR_ENGINE_DISTINCT_ID)
  object SolarEngineAccountId : AttributionIds(ReservedSubscriberAttribute.SOLAR_ENGINE_ACCOUNT_ID)
  object SolarEngineVisitorId : AttributionIds(ReservedSubscriberAttribute.SOLAR_ENGINE_VISITOR_ID)
  ```

**2. `purchases/src/defaults/kotlin/com/revenuecat/purchases/Purchases.kt`**
- Add three public methods:
  ```kotlin
  fun setSolarEngineDistinctId(solarEngineDistinctId: String?) {
      purchasesOrchestrator.setSolarEngineDistinctId(solarEngineDistinctId)
  }

  fun setSolarEngineAccountId(solarEngineAccountId: String?) {
      purchasesOrchestrator.setSolarEngineAccountId(solarEngineAccountId)
  }

  fun setSolarEngineVisitorId(solarEngineVisitorId: String?) {
      purchasesOrchestrator.setSolarEngineVisitorId(solarEngineVisitorId)
  }
  ```

**3. `purchases/src/main/kotlin/com/revenuecat/purchases/PurchasesOrchestrator.kt`**
- Add three methods:
  ```kotlin
  fun setSolarEngineDistinctId(solarEngineDistinctId: String?) {
      log(LogIntent.DEBUG) { AttributionStrings.METHOD_CALLED.format("setSolarEngineDistinctId") }
      subscriberAttributesManager.setAttributionID(
          SubscriberAttributeKey.AttributionIds.SolarEngineDistinctId,
          solarEngineDistinctId,
          appUserID,
          application,
      )
  }

  fun setSolarEngineAccountId(solarEngineAccountId: String?) {
      log(LogIntent.DEBUG) { AttributionStrings.METHOD_CALLED.format("setSolarEngineAccountId") }
      subscriberAttributesManager.setAttributionID(
          SubscriberAttributeKey.AttributionIds.SolarEngineAccountId,
          solarEngineAccountId,
          appUserID,
          application,
      )
  }

  fun setSolarEngineVisitorId(solarEngineVisitorId: String?) {
      log(LogIntent.DEBUG) { AttributionStrings.METHOD_CALLED.format("setSolarEngineVisitorId") }
      subscriberAttributesManager.setAttributionID(
          SubscriberAttributeKey.AttributionIds.SolarEngineVisitorId,
          solarEngineVisitorId,
          appUserID,
          application,
      )
  }
  ```

**4. Tests**
- Add unit tests following existing attribution test patterns

### Behavior
- Each method triggers automatic device identifier collection (GPS Ad ID, Android ID, IP) if enabled
- Attributes stored in SharedPreferences with `isSynced = false`
- Backend sync happens automatically via existing `SubscriberAttributesPoster`
- No changes to networking layer needed

## Backend Integration

### Endpoint
- Uses existing `POST /subscribers/{userId}/attributes` endpoint
- No backend changes required

### Attribute Format
Each attribute syncs independently:
```json
{
  "attributes": {
    "$solarEngineDistinctId": {
      "value": "distinct-id-value",
      "updated_at_ms": 1704470400000
    },
    "$solarEngineAccountId": {
      "value": "account-id-value",
      "updated_at_ms": 1704470400000
    },
    "$solarEngineVisitorId": {
      "value": "visitor-id-value",
      "updated_at_ms": 1704470400000
    }
  }
}
```

## Testing Strategy

### iOS Tests
- Unit tests in `PurchasesSubscriberAttributesTests.swift`
- Test setting non-nil values
- Test clearing with nil
- Verify manager methods are called correctly

### Android Tests
- Unit tests following existing attribution patterns
- Verify correct attribute keys are used
- Test null handling

## Documentation

### Comments
- Add DocC/KDoc comments to all public methods
- Reference Solar Engine integration docs (when available)

### Breaking Changes
- None - all changes are additive and backward compatible

## Summary

**Total Changes:**
- iOS: 3 enum cases, 3 public methods, 3 manager methods, 6-9 unit tests
- Android: 3 enum values, 3 attribute key objects, 3 public methods, 3 orchestrator methods, 6-9 unit tests

**Estimated Files Modified:**
- iOS: 4-5 files
- Android: 4-5 files

**Pattern Consistency:**
- Exactly matches Airbridge device ID implementation
- No new patterns or infrastructure needed
- Leverages all existing attribute sync mechanisms
