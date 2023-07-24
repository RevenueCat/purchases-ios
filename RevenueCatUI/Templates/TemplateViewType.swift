import RevenueCat
import SwiftUI

/// A `SwiftUI` view that can display a paywall with `TemplateViewConfiguration`.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
protocol TemplateViewType: SwiftUI.View {

    init(_ configuration: TemplateViewConfiguration)

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension PaywallTemplate {

    var packageSetting: TemplateViewConfiguration.PackageSetting {
        switch self {
        case .singlePackage: return .single
        case .multiPackage: return .multiple
        }
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension PaywallData {

    @ViewBuilder
    func createView(for offering: Offering, mode: PaywallViewMode) -> some View {
        switch self.configuration(for: offering, mode: mode) {
        case let .success(configuration):
            Self.createView(template: self.template, configuration: configuration)
                .background(
                    mode.shouldDisplayBackground
                    ? configuration.colors.backgroundColor
                    : nil
                )

        case let .failure(error):
            DebugErrorView(error, releaseBehavior: .emptyView)
        }
    }

    private func configuration(
        for offering: Offering,
        mode: PaywallViewMode
    ) -> Result<TemplateViewConfiguration, Error> {
        return Result {
            TemplateViewConfiguration(
                mode: mode,
                packages: try .create(with: offering.availablePackages,
                                      filter: self.config.packages,
                                      localization: self.localizedConfiguration,
                                      setting: self.template.packageSetting),
                configuration: self.config,
                colors: self.config.colors.multiScheme,
                imageURLs: self.imageURLs
            )
        }
    }

    @ViewBuilder
    private static func createView(template: PaywallTemplate,
                                   configuration: TemplateViewConfiguration) -> some View {
        switch template {
        case .singlePackage:
            SinglePackageTemplate(configuration)
        case .multiPackage:
            MultiPackageTemplate(configuration)
        }
    }

}

private extension PaywallViewMode {

    var shouldDisplayBackground: Bool {
        switch self {
        case .fullScreen: return true
        case .card, .banner: return false
        }
    }

}
