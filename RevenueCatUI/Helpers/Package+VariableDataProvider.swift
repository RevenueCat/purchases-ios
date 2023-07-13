import Foundation
import RevenueCat

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension Package: VariableDataProvider {

    var localizedPricePerMonth: String {
        return self.priceFormatter.string(from: self.pricePerMonth) ?? ""
    }

    var productName: String {
        return self.storeProduct.localizedTitle
    }

    var introductoryOfferDuration: String? {
        return self.introDuration
    }

}

// MARK: - Private

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension Package {

    var pricePerMonth: NSDecimalNumber {
        guard let price = self.storeProduct.pricePerMonth else {
            fatalError("Unexpectedly found a package which is not a subscription: \(self)")
        }

        return price
    }

    var priceFormatter: NumberFormatter {
        // `priceFormatter` can only be `nil` for SK2 products
        // with an unknown code, which should be rare.
        return self.storeProduct.priceFormatter ?? .init()
    }

    var introDuration: String? {
        return self.storeProduct.introductoryDiscount?.localizedDuration
    }

}
