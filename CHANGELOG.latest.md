## RevenueCat SDK

### Virtual Currencies

Warning: the virtual currency features are currently in beta and may change without notice.

#### Dedicated Function for Fetching Virtual Currencies

Virtual Currencies have been moved out of `CustomerInfo` and can now be fetched using the new `Purchases.shared.virtualCurrencies()` function, like so:

```swift
// With Async/Await
let virtualCurrencies = try? await Purchases.shared.virtualCurrencies()

// With Completion Handlers
Purchases.shared.virtualCurrencies { virtualCurrencies, error in

}
```

#### Refreshing the Virtual Currencies Cache

The `virtualCurrencies()` functions use caching behind the scenes. If you know a virtual currency's balance has changed (e.g., due to a backend update) you can refresh the cache like so:

```swift
Purchases.shared.invalidateVirtualCurrenciesCache()
```

This ensures that the next `virtualCurrencies()` call will update the latest virtual currency values from the RevenueCat backend.

#### Working with Virtual Currencies

After fetching the `VirtualCurrencies` object from the above functions, you can work with individual `VirtualCurrency` objects like so:

```swift
// Iterate through all virtual currencies
for (virtualCurrencyCode, virtualCurrency) in virtualCurrencies.all {
    print("\(virtualCurrencyCode): \(virtualCurrency.balance)")
}

// Access a specific virtual currency
let virtualCurrency = virtualCurrencies["{YOUR_VIRTUAL_CURRENCY_CODE_HERE}"]
```

#### Renaming & New Fields

The `VirtualCurrencyInfo` type has been renamed to `VirtualCurrency`, with the following new fields added:

- `name`: The name of the virtual currency as defined in the RevenueCat dashboard
- `code`: The virtual currency's code as defined in the RevenueCat dashboard
- `serverDescription`: The virtual currency's description as defined in the RevenueCat dashboard

### Commits

- [Virtual Currencies] Break VC Balances out of CustomerInfo (#5151) via Will Taylor (@fire-at-will)
