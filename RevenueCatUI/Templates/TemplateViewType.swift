import RevenueCat
import SwiftUI

/// A `SwiftUI` view that can display a paywall with `TemplateViewConfiguration`.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(tvOS, unavailable)
protocol TemplateViewType: SwiftUI.View {

    init(_ configuration: TemplateViewConfiguration)

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension PaywallTemplate {

    var packageSetting: TemplateViewConfiguration.PackageSetting {
        switch self {
        case .onePackageStandard: return .single
        case .multiPackageBold: return .multiple
        case .onePackageWithFeatures: return .single
        }
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(tvOS, unavailable)
extension PaywallData {

    @ViewBuilder
    func createView(for offering: Offering,
                    mode: PaywallViewMode,
                    introEligibility: IntroEligibilityViewModel,
                    locale: Locale) -> some View {
        switch self.configuration(for: offering, mode: mode, locale: locale) {
        case let .success(configuration):
            Self.createView(template: self.template, configuration: configuration)
                .task(id: offering) {
                    await introEligibility.computeEligibility(for: configuration.packages)
                }
                .background(
                    Rectangle()
                        .foregroundColor(
                            mode.shouldDisplayBackground
                            ? configuration.colors.backgroundColor
                            : .clear
                        )
                        .edgesIgnoringSafeArea(.all)
                )

        case let .failure(error):
            DebugErrorView(error, releaseBehavior: .emptyView)
        }
    }

    func configuration(
        for offering: Offering,
        mode: PaywallViewMode,
        locale: Locale
    ) -> Result<TemplateViewConfiguration, Error> {
        return Result {
            TemplateViewConfiguration(
                mode: mode,
                packages: try .create(with: offering.availablePackages,
                                      filter: self.config.packages,
                                      default: self.config.defaultPackage,
                                      localization: self.localizedConfiguration,
                                      setting: self.template.packageSetting,
                                      locale: locale),
                configuration: self.config,
                colors: self.config.colors.multiScheme,
                assetBaseURL: self.assetBaseURL
            )
        }
    }

    @ViewBuilder
    private static func createView(template: PaywallTemplate,
                                   configuration: TemplateViewConfiguration) -> some View {
        switch template {
        case .onePackageStandard:
            OnePackageStandardTemplate(configuration)
        case .multiPackageBold:
            MultiPackageBoldTemplate(configuration)
        case .onePackageWithFeatures:
            OnePackageWithFeaturesTemplate(configuration)
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
