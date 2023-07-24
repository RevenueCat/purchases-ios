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
        self._selectedPackage = .init(initialValue: configuration.packages.single.content)

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
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            }
    }

    @ViewBuilder
    var content: some View {
        VStack(spacing: 10) {
            self.iconImage
                .padding(.top)

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
                    .foregroundColor(
                        selected
                        ? self.configuration.colors.callToActionBackgroundColor
                        : .gray
                    )

                Text(package.content.productName)
            }
            .foregroundColor(self.configuration.colors.callToActionBackgroundColor)

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
                .foregroundColor(selected ? .black : .init(white: 0.8))
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
        if let url = self.configuration.backgroundURL {
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
        if let url = self.configuration.iconURL {
            RemoteImage(url: url, aspectRatio: 1)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .frame(maxWidth: 100)
        } else {
            DebugErrorView("Template configuration is missing icon URL",
                           releaseBehavior: .emptyView)
        }
    }

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
private extension TemplateViewConfiguration {

    var backgroundURL: URL? {
        return self.imageURLs.first
    }

    var iconURL: URL? {
        guard self.imageURLs.count >= 2 else { return nil }
        return self.imageURLs[1]
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct PackageButtonStyle: ButtonStyle {

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
    }

}
