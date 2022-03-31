# Deprecations 📼

## Deprecated vs Obsoleted:

As the framework evolves, some APIs change. For Version 4 there's a [general document](https://revenuecat-docs.netlify.app/documentation/revenuecat/v4_api_migration_guide) listing all the changes. For code, APIs can be marked as `deprecated` or `obsoleted`. These annotations can also provide information about the API that it's being replaced with.

### Deprecated ⚠️
APIs marked as `deprecated` mean that a method or type can continue to be used, but it provides a warning to the developer letting them know that it will go away in a future version.

Because they can still be called, the implementations need to remain valid. Some of these live in `Deprecations.swift`.

### Obsoleted ⛔️
APIs marked as `obsoleted` result in a compile error, they can't be used.
Because they can't be called, these are moved to `Obsoletions.swift` and their implementations removed, since it doesn't need to be valid or maintained.

For methods, a simple `fatalError()` is enough.
Types can be left empty.

## Examples:

### Renamed type:
```swift
@available(iOS, obsoleted: 1, renamed: "CustomerInfo")
@available(tvOS, obsoleted: 1, renamed: "CustomerInfo")
@available(watchOS, obsoleted: 1, renamed: "CustomerInfo")
@available(macOS, obsoleted: 1, renamed: "CustomerInfo")
@objc(RCPurchaserInfo) public class PurchaserInfo: NSObject { }
```
Note:
- `@objc` annotation still provides the old Objective-C type name.
- `renamed:` lets the compiler provide a more useful message and a fix-it.
- The version specified in `obsoleted` is `1`, meaning it's obsoleted in any version  equal or higher than that.
- Each platform needs to be specified independently.

### Renamed method with `@objc` annotation:
```swift
@available(iOS, obsoleted: 1, renamed: "getProducts(_:completion:)")
@available(tvOS, obsoleted: 1, renamed: "getProducts(_:completion:)")
@available(watchOS, obsoleted: 1, renamed: "getProducts(_:completion:)")
@available(macOS, obsoleted: 1, renamed: "getProducts(_:completion:)")
@objc(productsWithIdentifiers:completion:)
func products(_ productIdentifiers: [String], completion: @escaping ([SKProduct]) -> Void) {
    fatalError()
}
```

Note:
- `@objc` annotation indicates the old Objective-C method name.
- `fatalError()` is fine because the method cannot be called.

### Obsoleted methods with _new_ APIs

Another example is a method that needs to be obsoleted, but it also uses types that aren't available in our minimum deployment target. This means that they require an `introduced` version, as well as `obsoleted`. Consider `SKPaymentDiscount` which was introduced in `iOS 12.2`.

One might think that this could work:
```swift
@available(iOS, obsoleted: 1, renamed: "purchase(product:discount:)")
@available(tvOS, obsoleted: 1, renamed: "purchase(product:discoun:)")
@available(watchOS, obsoleted: 1, renamed: "purchase(product:discount:)")
@available(macOS, obsoleted: 1, renamed: "purchase(product:discount:)")
@available(iOS 12.2, macOS 10.14.4, macCatalyst 13.0, tvOS 12.2, watchOS 6.2, *)
func purchaseProduct(_ product: SKProduct, discount: SKPaymentDiscount)
```

However, that would result in warnings (for some reason only if the method also has an `@objc` annotation), and invalid code generation:
> Feature cannot be obsoleted in iOS version 1 before it was introduced in version 12.2; attribute ignored

The correct way is to have the `introduced` version and also mark it as `unavailable`:
```swift
@available(iOS, introduced: 12.2, unavailable, renamed: "purchase(product:discount:)")
@available(tvOS, introduced: 12.2, unavailable, renamed: "purchase(product:discount:)")
@available(watchOS, introduced: 6.2, unavailable, renamed: "purchase(product:discount:)")
@available(macOS, introduced: 10.14.4, unavailable, renamed: "purchase(product:discount:)")
@available(macCatalyst, introduced: 13.0, unavailable, renamed: "purchase(product:discount:)")
func purchaseProduct(_ product: SKProduct, discount: SKPaymentDiscount)
```

## Issues

- When using a `renamed` API from another module, Swift produces the wrong diagnostic: https://github.com/RevenueCat/purchases-ios/issues/1008
