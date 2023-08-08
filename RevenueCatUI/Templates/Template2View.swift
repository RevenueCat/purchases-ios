import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(tvOS, unavailable)
struct Template2View: TemplateViewType {

    let configuration: TemplateViewConfiguration
    private var localization: [Package: ProcessedLocalizedConfiguration]

    @State
    private var selectedPackage: Package

    @EnvironmentObject
    private var introEligibilityViewModel: IntroEligibilityViewModel
    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    init(_ configuration: TemplateViewConfiguration) {
        self._selectedPackage = .init(initialValue: configuration.packages.default.content)

        self.configuration = configuration
        self.localization = configuration.packages.localizationPerPackage()
    }

    var body: some View {
        self.content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                TemplateBackgroundImageView(configuration: self.configuration)
            }
    }

    @ViewBuilder
    var content: some View {
        VStack(spacing: 10) {
            self.scrollableContent
                .scrollableIfNecessary()

            self.subscribeButton
                .padding(.horizontal)

            if case .fullScreen = self.configuration.mode {
                FooterView(configuration: self.configuration,
                           color: self.configuration.colors.text1Color,
                           purchaseHandler: self.purchaseHandler)
            }
        }
        .animation(Constants.fastAnimation, value: self.selectedPackage)
        .multilineTextAlignment(.center)
        .frame(maxHeight: .infinity)
    }

    private var scrollableContent: some View {
        VStack {
            Spacer()

            self.iconImage

            Spacer()

            Text(.init(self.selectedLocalization.title))
                .foregroundColor(self.configuration.colors.text1Color)
                .font(self.font(for: .largeTitle).bold())

            Spacer()

            Text(.init(self.selectedLocalization.subtitle ?? ""))
                .foregroundColor(self.configuration.colors.text1Color)
                .font(self.font(for: .title3))

            Spacer()

            self.packages

            Spacer()
        }
        .padding(.horizontal)
        .frame(maxHeight: .infinity)
    }

    private var packages: some View {
        VStack(spacing: 8) {
            ForEach(self.configuration.packages.all, id: \.content.id) { package in
                let isSelected = self.selectedPackage === package.content

                Button {
                    self.selectedPackage = package.content
                } label: {
                    self.packageButton(package, selected: isSelected)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PackageButtonStyle(isSelected: isSelected))
            }
        }
    }

    @ViewBuilder
    private func packageButton(_ package: TemplateViewConfiguration.Package, selected: Bool) -> some View {
        VStack(alignment: Self.packageButtonAlignment.horizontal, spacing: 5) {
            self.packageButtonTitle(package, selected: selected)

            IntroEligibilityStateView(
                textWithNoIntroOffer: package.localization.offerDetails,
                textWithIntroOffer: package.localization.offerDetailsWithIntroOffer,
                introEligibility: self.introEligibility[package.content],
                foregroundColor: self.textColor(selected),
                alignment: Self.packageButtonAlignment
            )
            .fixedSize(horizontal: false, vertical: true)
            .font(self.font(for: .body))
        }
        .font(self.font(for: .body).weight(.medium))
        .padding()
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: Self.packageButtonAlignment)
        .overlay {
            if selected {
                EmptyView()
            } else {
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .stroke(self.configuration.colors.text1Color, lineWidth: 2)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .foregroundColor(
                    selected
                    ? self.selectedBackgroundColor
                    : .clear
                )
        }
    }

    private func packageButtonTitle(
        _ package: TemplateViewConfiguration.Package,
        selected: Bool
    ) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .hidden(if: !selected)
                .overlay {
                    if selected {
                        EmptyView()
                    } else {
                        Circle()
                            .foregroundColor(self.selectedBackgroundColor.opacity(0.5))
                    }
                }

            Text(self.localization(for: package.content).offerName ?? package.content.productName)
        }
        .foregroundColor(self.textColor(selected))
    }

    private func textColor(_ selected: Bool) -> Color {
        return selected
        ? self.configuration.colors.accent1Color
        : self.configuration.colors.text1Color
    }

    private var subscribeButton: some View {
        PurchaseButton(
            package: self.selectedPackage,
            localization: self.selectedLocalization,
            configuration: self.configuration,
            introEligibility: self.introEligibility[self.selectedPackage],
            purchaseHandler: self.purchaseHandler
        )
    }

    @ViewBuilder
    private var iconImage: some View {
        Group {
            #if canImport(UIKit)
            if let url = self.configuration.iconImageURL {
                Group {
                    if url.pathComponents.contains(PaywallData.appIconPlaceholder) {
                        if let appIcon = Bundle.main.appIcon {
                            Image(uiImage: appIcon)
                                .resizable()
                                .frame(width: self.appIconSize, height: self.appIconSize)
                        } else {
                            self.placeholderIconImage
                        }
                    } else {
                        RemoteImage(url: url, aspectRatio: 1, maxWidth: self.iconSize)
                    }
                }
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                self.placeholderIconImage
            }
            #else
            self.placeholderIconImage
            #endif
        }
        .padding(.top)
    }

    private var placeholderIconImage: some View {
        // Placeholder to be able to add a consistent padding
        Text(verbatim: "")
            .hidden()
    }

    // MARK: -

    private var introEligibility: [Package: IntroEligibilityStatus] {
        return self.introEligibilityViewModel.allEligibility
    }

    private var selectedBackgroundColor: Color { self.configuration.colors.accent2Color }

    @ScaledMetric(relativeTo: .largeTitle)
    private var appIconSize: CGFloat = 100
    @ScaledMetric(relativeTo: .largeTitle)
    private var iconSize: CGFloat = 140
    private static let cornerRadius: CGFloat = 15
    private static let packageButtonAlignment: Alignment = .leading

}

// MARK: - Extensions

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(tvOS, unavailable)
private extension Template2View {

    func localization(for package: Package) -> ProcessedLocalizedConfiguration {
        // Because of how packages are constructed this is known to exist
        return self.localization[package]!
    }

    var selectedLocalization: ProcessedLocalizedConfiguration {
        return self.localization(for: self.selectedPackage)
    }

}

#if canImport(UIKit)
private extension Bundle {

    var appIcon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return .init(named: lastIcon)
        }
        return nil
    }

}
#endif

// MARK: -

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(macCatalyst, unavailable)
struct Template2View_Previews: PreviewProvider {

    static var previews: some View {
        PreviewableTemplate(offering: TestData.offeringWithMultiPackagePaywall) {
            Template2View($0)
        }
    }

}

#endif
