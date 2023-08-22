import Foundation
import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension Package: VariableDataProvider {

    var applicationName: String {
        return Bundle.main.applicationDisplayName
    }

    var localizedPrice: String {
        return self.storeProduct.localizedPriceString
    }

    var localizedPricePerMonth: String {
        return self.priceFormatter.string(from: self.pricePerMonth) ?? ""
    }

    var localizedIntroductoryOfferPrice: String? {
        return self.storeProduct.introductoryDiscount?.localizedPriceString
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

    func localizedPricePerPeriod(_ locale: Locale) -> String {
        guard let period = self.storeProduct.subscriptionPeriod else {
            return self.localizedPrice
        }

        let unit = Localization.abbreviatedUnitLocalizedString(for: period.unit, locale: locale)
        return "\(self.localizedPrice)/\(unit)"
    }

    func localizedPriceAndPerMonth(_ locale: Locale) -> String {
        if !self.isSubscription || self.isMonthly {
            return self.localizedPricePerPeriod(locale)
        } else {
            let unit = Localization.abbreviatedUnitLocalizedString(for: .month, locale: locale)
            return "\(self.localizedPrice) (\(self.localizedPricePerMonth)/\(unit))"
        }
    }

}

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension Package {

    var isSubscription: Bool {
        return self.storeProduct.productCategory == .subscription
    }

    var isMonthly: Bool {
        return self.storeProduct.subscriptionPeriod == SubscriptionPeriod(value: 1, unit: .month)
    }

    var pricePerMonth: NSDecimalNumber {
        guard let price = self.storeProduct.pricePerMonth else {
            Logger.warning(Strings.package_not_subscription(self))
            return self.storeProduct.priceDecimalNumber
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
