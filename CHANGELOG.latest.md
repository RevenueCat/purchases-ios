### 🔄 Other Changes
* Adds `showStoreMessagesAutomatically` parameter to CEC mode (#5222) via JayShortway (@JayShortway)
* Updates changelog via JayShortway
* Updates version number via JayShortway
* Add promotional offer APIs to `CustomEntitlementComputation` V4 SDK (#4973) via Toni Rico (@tonidero)
* update gems via Mark Villacampa
* update gems via Mark Villacampa
* Version bump for 4.43.4 via Mark Villacampa
* update fastlane via Mark Villacampa
* v4: Fix crash in iOS 11-12 when using MainActor (#4718)

* Fix crash on iOS 11 and 12 when compiling with Xcode 16 and instantiating an array with type @MainActor lambda

var foo: [@MainActor @Sendable () -> Void] = []

* fix

* removed one problematic MainActor reference

* Make the internal block type non-@MainActor, and make it wrap the external @MainActor block.

This way we avoid hitting the iOS 11 crash when initiailising a collection with a @MainActor block type, and we dont change the public interface.

* fix leak

* removed reference to @MainActor when getting the completion block

* remove @MainActor from the optional return type as it crashes when accessing the type metadata because the  method is generic

* Update Purchases.swift

---------

Co-authored-by: Andy Boedo <andresboedo@gmail.com> via Mark Villacampa
* Fix test via Mark Villacampa
* Fix lint via Mark Villacampa
* Version bump for 4.43.3 via Mark Villacampa
* Remove usage of adServicesToken in syncPurchases via Mark Villacampa
* Update RevenueCat-Swift.h for version 4.43.2 via RCGitBot
* Version bump for 4.43.2 via RCGitBot
