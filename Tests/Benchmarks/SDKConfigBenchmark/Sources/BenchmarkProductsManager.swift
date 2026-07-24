import Foundation

/// StoreKit-free `ProductsManagerType` so the benchmark measures the SDK's fetch and decode
/// paths, not App Store product lookups. Every requested identifier resolves immediately to a
/// synthesized monthly subscription, the same way UI preview mode fabricates products.
final class BenchmarkProductsManager: ProductsManagerType {

    let requestTimeout: TimeInterval = 30

    func products(
        withIdentifiers identifiers: Set<String>,
        completion: @escaping ProductsManagerType.Completion
    ) {
        let products = identifiers.map { identifier in
            TestStoreProduct(
                localizedTitle: "Benchmark Monthly",
                price: 9.99,
                localizedPriceString: "$9.99",
                productIdentifier: identifier,
                productType: .autoRenewableSubscription,
                localizedDescription: "Benchmark subscription",
                subscriptionGroupIdentifier: "benchmark.group",
                subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month)
            ).toStoreProduct()
        }
        completion(.success(Set(products)))
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2Products(
        withIdentifiers identifiers: Set<String>,
        completion: @escaping ProductsManagerType.SK2Completion
    ) {
        completion(.success([]))
    }

    func cache(_ product: StoreProductType) {}

    func clearCache() {}

}
