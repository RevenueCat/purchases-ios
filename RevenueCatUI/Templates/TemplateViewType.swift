import RevenueCat
import SwiftUI

/// A `SwiftUI` view that can display a paywall with `TemplateViewConfiguration`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(tvOS, unavailable)
protocol TemplateViewType: SwiftUI.View {

    var configuration: TemplateViewConfiguration { get }

    init(_ configuration: TemplateViewConfiguration)

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension TemplateViewType {

    func font(for textStyle: Font.TextStyle) -> Font {
        return self.configuration.fonts.font(for: textStyle)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallTemplate {

    var packageSetting: TemplateViewConfiguration.PackageSetting {
        switch self {
        case .template1: return .single
        case .template2: return .multiple
        case .template3: return .single
        case .template4: return .multiple
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(tvOS, unavailable)
extension PaywallData {

    @ViewBuilder
    func createView(for offering: Offering,
                    mode: PaywallViewMode,
                    fonts: PaywallFontProvider,
                    introEligibility: IntroEligibilityViewModel,
                    locale: Locale) -> some View {
        switch self.configuration(for: offering, mode: mode, fonts: fonts, locale: locale) {
        case let .success(configuration):
            Self.createView(template: self.template, configuration: configuration)
                .task(id: offering) {
                    await introEligibility.computeEligibility(for: configuration.packages)
                }
                .background(self.background(configuration: configuration))

        case let .failure(error):
            DebugErrorView(error, releaseBehavior: .emptyView)
        }
    }

    @ViewBuilder
    private func background(
        configuration: TemplateViewConfiguration
    ) -> some View {
        let view = Rectangle()
            .foregroundStyle(configuration.colors.backgroundColor)
            .edgesIgnoringSafeArea(.all)

        switch configuration.mode {
        case .fullScreen:
            view
        case .card, .condensedCard:
            view
            #if canImport(UIKit)
                .roundedCorner(
                    Constants.defaultCornerRadius,
                    corners: [.topLeft, .topRight],
                    edgesIgnoringSafeArea: .all
                )
            #endif
        }
    }

    func configuration(
        for offering: Offering,
        mode: PaywallViewMode,
        fonts: PaywallFontProvider,
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
                fonts: fonts,
                assetBaseURL: self.assetBaseURL
            )
        }
    }

    @ViewBuilder
    private static func createView(template: PaywallTemplate,
                                   configuration: TemplateViewConfiguration) -> some View {
        switch template {
        case .template1:
            Template1View(configuration)
        case .template2:
            Template2View(configuration)
        case .template3:
            Template3View(configuration)
        case .template4:
            Template4View(configuration)
        }
    }

}
