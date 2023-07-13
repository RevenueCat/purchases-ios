import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
protocol TemplateViewType: SwiftUI.View {

    init(
        packages: [Package],
        localization: PaywallData.LocalizedConfiguration,
        configuration: PaywallData.Configuration
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
                configuration: self.config
            )
        }
    }
}
