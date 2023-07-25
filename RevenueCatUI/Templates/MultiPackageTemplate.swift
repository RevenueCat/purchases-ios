import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct MultiPackageTemplate: TemplateViewType {

    private let configuration: TemplateViewConfiguration

    @EnvironmentObject
    private var introEligibilityChecker: TrialOrIntroEligibilityChecker

    @State
    private var introEligibility: [Package: IntroEligibilityStatus] = [:]

    init(_ configuration: TemplateViewConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        MultiPackageTemplateContent(configuration: self.configuration,
                                    introEligibility: self.introEligibility)
        .task(id: self.configuration.packages) {
            self.introEligibility = await self.introEligibilityChecker.eligibility(
                for: self.configuration.packages.all.map(\.content)
            )
        }
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct MultiPackageTemplateContent: View {

    private var configuration: TemplateViewConfiguration
    private var introEligibility: [Package: IntroEligibilityStatus]
    private var localization: [Package: ProcessedLocalizedConfiguration]

    @State
    private var selectedPackage: Package

    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler
    @Environment(\.dismiss)
    private var dismiss

    init(configuration: TemplateViewConfiguration, introEligibility: [Package: IntroEligibilityStatus]) {
        self._selectedPackage = .init(initialValue: configuration.packages.default.content)

        self.configuration = configuration
        self.introEligibility = introEligibility
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
            self.iconImage

            ViewThatFits(in: .vertical) {
                self.scrollableContent

                ScrollView {
                    self.scrollableContent
                }
                    .scrollBounceBehaviorBasedOnSize()
            }

            self.subscribeButton
                .padding(.horizontal)

            if case .fullScreen = self.configuration.mode {
                FooterView(configuration: self.configuration.configuration,
                           colors: self.configuration.colors,
                           purchaseHandler: self.purchaseHandler)
            }
        }
        .animation(.easeInOut(duration: 0.1), value: self.selectedPackage)
        .frame(maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .frame(maxHeight: .infinity)
    }

    private var scrollableContent: some View {
        VStack {
            Text(self.selectedLocalization.title)
                .font(.largeTitle.bold())

            Spacer()

            Text(self.selectedLocalization.subtitle)
                .font(.title2)

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
                Button {
                    self.selectedPackage = package.content
                } label: {
                    self.packageButton(package, selected: self.selectedPackage === package.content)
                }
                .buttonStyle(PackageButtonStyle())
            }
        }
        .padding(.bottom)
    }

    @ViewBuilder
    private func packageButton(_ package: TemplateViewConfiguration.Package, selected: Bool) -> some View {
        let alignment: Alignment = .leading

        VStack(alignment: alignment.horizontal, spacing: 5) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .hidden(if: !selected)
                    .overlay {
                        if selected {
                            EmptyView()
                        } else {
                            Circle()
                                .foregroundColor(Self.selectedBackgroundColor.opacity(0.5))
                        }
                    }

                Text(self.localization(for: package.content).offerName ?? package.content.productName)
            }
            .foregroundColor(self.configuration.colors.accent1Color)

            IntroEligibilityStateView(
                textWithNoIntroOffer: package.localization.offerDetails,
                textWithIntroOffer: package.localization.offerDetailsWithIntroOffer,
                introEligibility: self.introEligibility[package.content],
                foregroundColor: selected
                    ? .white
                    : .black,
                alignment: alignment
            )
            .fixedSize(horizontal: false, vertical: true)
            .font(.body)
        }
        .font(.body.weight(.medium))
        .padding()
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: alignment)
        .foregroundColor(self.configuration.colors.foregroundColor)
        .background {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .foregroundColor(
                    selected
                    ? Self.selectedBackgroundColor
                    : .clear
                )
        }
    }

    private var subscribeButton: some View {
        PurchaseButton(
            package: self.selectedPackage,
            purchaseHandler: self.purchaseHandler,
            colors: self.configuration.colors,
            localization: self.selectedLocalization,
            introEligibility: self.introEligibility[self.selectedPackage],
            mode: self.configuration.mode
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
        } else {
            DebugErrorView("Template configuration is missing background URL",
                           releaseBehavior: .emptyView)
        }
    }

    @ViewBuilder
    private var iconImage: some View {
        Group {
            if let url = self.configuration.iconImageURL {
                RemoteImage(url: url, aspectRatio: 1, maxWidth: Self.iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                // Placeholder to be able to add a consistent padding
                Text(verbatim: "")
                    .hidden()
            }
        }
        .padding(.top)
    }

    private static let iconSize: CGFloat = 100

    #if !os(macOS) && !os(watchOS)
    private static let selectedBackgroundColor: Color = .init(
        light: .init(white: 0.3),
        dark: .init(white: 0.6)
    )
    #else
    private static let selectedBackgroundColor: Color = .init(white: 0.3)
    #endif

}

// MARK: - Extensions

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension MultiPackageTemplateContent {

    func localization(for package: Package) -> ProcessedLocalizedConfiguration {
        // Because of how packages are constructed this is known to exist
        return self.localization[package]!
    }

    var selectedLocalization: ProcessedLocalizedConfiguration {
        return self.localization(for: self.selectedPackage)
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct PackageButtonStyle: ButtonStyle {

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
    }

}
