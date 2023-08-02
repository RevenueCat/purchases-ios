import Foundation
import RevenueCat

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension Package: VariableDataProvider {

    var applicationName: String {
        return Bundle.main.applicationDisplayName
    }

    var isMonthly: Bool {
        return self.packageType == .monthly
    }

    var localizedPrice: String {
        return self.storeProduct.localizedPriceString
    }

    var localizedPricePerMonth: String {
        return self.priceFormatter.string(from: self.pricePerMonth) ?? ""
    }

    var productName: String {
        return self.storeProduct.localizedTitle
    }

    func periodName(_ locale: Locale) -> String {
        return Localization.localized(packageType: self.packageType,
                                      locale: locale)
    }

    func subscriptionDuration(_ locale: Locale) -> String? {
        return self.periodDuration(locale)
    }

    func introductoryOfferDuration(_ locale: Locale) -> String? {
        return self.introDuration(locale)
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

    func periodDuration(_ locale: Locale) -> String? {
        guard let period = self.storeProduct.subscriptionPeriod else { return nil }

        return Localization.localizedDuration(for: period, locale: locale)
    }

    func introDuration(_ locale: Locale) -> String? {
        guard let discount = self.storeProduct.introductoryDiscount else { return nil }

        return Localization.localizedDuration(for: discount.subscriptionPeriod, locale: locale)
    }

}

private extension Bundle {

    var applicationDisplayName: String {
        return self.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? self.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? ""
    }

}
