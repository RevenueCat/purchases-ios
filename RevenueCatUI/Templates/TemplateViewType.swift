import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
protocol TemplateViewType: SwiftUI.View {

    init(
        packages: [Package],
        localization: PaywallData.LocalizedConfiguration,
        paywall: PaywallData
    )

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension PaywallData {

    @ViewBuilder
    func createView(for offering: Offering) -> some View {
        switch self.template {
        case .example1:
            Example1Template(
                packages: offering.availablePackages,
                localization: self.localizedConfiguration,
                paywall: self
            )
        }
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension TemplateViewType {

    static func filter(packages: [Package], with list: [PackageType]) -> [Package] {
        // Only subscriptions are supported at the moment
        let subscriptions = packages.filter { $0.storeProduct.productCategory == .subscription }
        let map = Dictionary(grouping: subscriptions) { $0.packageType }

        return list.compactMap { type in
            if let packages = map[type] {
                switch packages.count {
                case 0:
                    // This isn't actually possible because of `Dictionary(grouping:by:)
                    return nil
                case 1:
                    return packages.first
                default:
                    Logger.warning("Found multiple \(type) packages. Will use the first one.")
                    return packages.first
                }
            } else {
                Logger.warning("Couldn't find '\(type)'")
                return nil
            }
        }
    }

}
