import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct MultiPackageBoldTemplate: TemplateViewType {

    private let configuration: TemplateViewConfiguration
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
        self.localization = Dictionary(
            uniqueKeysWithValues: configuration.packages.all
                .lazy
                .map { ($0.content, $0.localization) }
            )
    }

    var body: some View {
        self.content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                self.backgroundImage
                    .unredacted()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
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
                FooterView(configuration: self.configuration.configuration,
                           color: self.configuration.colors.text1Color,
                           purchaseHandler: self.purchaseHandler)
            }
        }
        .animation(Constants.fastAnimation, value: self.selectedPackage)
        .frame(maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .frame(maxHeight: .infinity)
    }

    private var scrollableContent: some View {
        VStack {
            Spacer()

            self.iconImage

            Spacer()

            Text(self.selectedLocalization.title)
                .foregroundColor(self.configuration.colors.text1Color)
                .font(.largeTitle.bold())

            Spacer()

            Text(self.selectedLocalization.subtitle ?? "")
                .foregroundColor(self.configuration.colors.text1Color)
                .font(.title3)

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
                foregroundColor: selected
                    ? self.configuration.colors.backgroundColor
                    : self.configuration.colors.text1Color,
                alignment: Self.packageButtonAlignment
            )
            .fixedSize(horizontal: false, vertical: true)
            .font(.body)
        }
        .font(.body.weight(.medium))
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
        .foregroundColor(
            selected
            ? self.configuration.colors.accent1Color
            : self.configuration.colors.text1Color
        )
    }

    private var subscribeButton: some View {
        PurchaseButton(
            package: self.selectedPackage,
            colors: self.configuration.colors,
            localization: self.selectedLocalization,
            introEligibility: self.introEligibility[self.selectedPackage],
            mode: self.configuration.mode,
            purchaseHandler: self.purchaseHandler
        )
    }

    @ViewBuilder
    private var backgroundImage: some View {
        if let url = self.configuration.backgroundImageURL {
            if self.configuration.configuration.blurredBackgroundImage {
                RemoteImage(url: url)
                    .blur(radius: 40)
                    .opacity(0.7)
            } else {
                RemoteImage(url: url)
            }
        }
    }

    @ViewBuilder
    private var iconImage: some View {
        Group {
            if let url = self.configuration.iconImageURL {
                RemoteImage(url: url, aspectRatio: 1, maxWidth: self.iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                // Placeholder to be able to add a consistent padding
                Text(verbatim: "")
                    .hidden()
            }
        }
        .padding(.top)
    }

    // MARK: -

    private var introEligibility: [Package: IntroEligibilityStatus] {
        return self.introEligibilityViewModel.allEligibility
    }

    private var selectedBackgroundColor: Color { self.configuration.colors.accent2Color }

    @ScaledMetric(relativeTo: .largeTitle)
    private var iconSize: CGFloat = 140
    private static let cornerRadius: CGFloat = 15
    private static let packageButtonAlignment: Alignment = .leading

}

// MARK: - Extensions

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension MultiPackageBoldTemplate {

    func localization(for package: Package) -> ProcessedLocalizedConfiguration {
        // Because of how packages are constructed this is known to exist
        return self.localization[package]!
    }

    var selectedLocalization: ProcessedLocalizedConfiguration {
        return self.localization(for: self.selectedPackage)
    }

}

// MARK: -

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
struct MultiPackageBoldTemplate_Previews: PreviewProvider {

    static var previews: some View {
        PreviewableTemplate(offering: TestData.offeringWithMultiPackagePaywall) {
            MultiPackageBoldTemplate($0)
        }
    }

}

#endif
