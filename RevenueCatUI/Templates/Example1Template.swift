import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct Example1Template: TemplateViewType {

    private var data: Result<Example1TemplateContent.Data, Example1TemplateContent.Error>

    @EnvironmentObject
    private var introEligibilityChecker: TrialOrIntroEligibilityChecker

    @State
    private var introEligibility: IntroEligibilityStatus?

    init(
        packages: [Package],
        localization: PaywallData.LocalizedConfiguration,
        paywall: PaywallData,
        colors: PaywallData.Configuration.Colors
    ) {
        // Fix-me: move this logic out to be used by all templates
        if packages.isEmpty {
            self.data = .failure(.noPackages)
        } else {
            let allPackages = paywall.config.packages
            let packages = PaywallData.filter(packages: packages, with: allPackages)

            if let package = packages.first {
                self.data = .success(.init(
                    package: package,
                    localization: localization.processVariables(with: package),
                    configuration: paywall.config,
                    headerImageURL: paywall.headerImageURL,
                    colors: colors
                ))
            } else {
                self.data = .failure(.couldNotFindAnyPackages(expectedTypes: allPackages))
            }
        }
    }

    // Fix-me: this can be extracted to be used by all templates
    var body: some View {
        switch self.data {
        case let .success(data):
            Example1TemplateContent(data: data, introEligibility: self.introEligibility)
                .task(id: self.package) {
                    if let package = self.package {
                        self.introEligibility = await self.introEligibilityChecker.eligibility(for: package)
                    }
                }

        case let .failure(error):
            // Fix-me: consider changing this behavior once we understand
            // how unlikely we can make this to happen thanks to server-side validations.
            DebugErrorView(error, releaseBehavior: .emptyView)
        }
    }

    private var package: Package? {
        return (try? self.data.get())?.package
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct Example1TemplateContent: View {

    private var data: Data
    private var introEligibility: IntroEligibilityStatus?

    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler
    @Environment(\.dismiss)
    private var dismiss

    init(data: Data, introEligibility: IntroEligibilityStatus?) {
        self.data = data
        self.introEligibility = introEligibility
    }

    var body: some View {
        ZStack {
            self.content
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack {
            ScrollView(.vertical) {
                VStack {
                    AsyncImage(
                        url: self.data.headerImageURL,
                        transaction: .init(animation: Constants.defaultAnimation)
                    ) { phase in
                        if let image = phase.image {
                            image
                                .fitToAspect(Self.imageAspectRatio, contentMode: .fill)
                        } else if let error = phase.error {
                            DebugErrorView("Error loading image from '\(self.data.headerImageURL)': \(error)",
                                           releaseBehavior: .emptyView)
                        } else {
                            Rectangle()
                                .hidden()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(Self.imageAspectRatio, contentMode: .fit)
                    .clipShape(
                        Circle()
                            .offset(y: -140)
                            .scale(3.0)
                    )
                    .padding(.bottom)

                    Spacer()

                    Group {
                        Text(verbatim: self.data.localization.title)
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .padding(.bottom)

                        Text(verbatim: self.data.localization.subtitle)
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                }
                .foregroundColor(self.data.colors.foregroundColor)
                .multilineTextAlignment(.center)
            }
            .scrollContentBackground(.hidden)
            .scrollBounceBehaviorBasedOnSize()
            .scrollIndicators(.automatic)
            .edgesIgnoringSafeArea(.top)

            Spacer()

            self.offerDetails
            self.button
                .padding(.horizontal)
        }
        .background(self.data.colors.backgroundColor)
    }

    private var offerDetails: some View {
        let detailsWithIntroOffer = self.data.localization.offerDetailsWithIntroOffer

        func text() -> String {
            if let detailsWithIntroOffer = detailsWithIntroOffer, self.isEligibleForIntro {
                return detailsWithIntroOffer
            } else {
                return self.data.localization.offerDetails
            }
        }

        return Text(verbatim: text())
            // Hide until we've determined intro eligibility
            // only if there is a custom intro offer string.
            .withPendingData(self.needsToWaitForIntroEligibility(detailsWithIntroOffer != nil))
            .font(.callout)
    }

    private var ctaText: some View {
        let ctaWithIntroOffer = self.data.localization.callToActionWithIntroOffer

        func text() -> String {
            if let ctaWithIntroOffer = ctaWithIntroOffer, self.isEligibleForIntro {
                return ctaWithIntroOffer
            } else {
                return self.data.localization.callToAction
            }
        }

        return Text(verbatim: text())
            // Hide until we've determined intro eligibility
            // only if there is a custom intro offer string.
            .withPendingData(self.needsToWaitForIntroEligibility(ctaWithIntroOffer != nil))
    }

    private var isEligibleForIntro: Bool {
        return self.introEligibility?.isEligible != false
    }

    private func needsToWaitForIntroEligibility(_ hasCustomString: Bool) -> Bool {
        return self.introEligibility == nil && hasCustomString && self.isEligibleForIntro
    }

    @ViewBuilder
    private var button: some View {
        AsyncButton {
            let cancelled = try await self.purchaseHandler.purchase(package: self.data.package).userCancelled

            if !cancelled {
                await self.dismiss()
            }
        } label: {
            self.ctaText
                .foregroundColor(self.data.colors.callToActionForegroundColor)
                .frame(maxWidth: .infinity)
        }
        .font(.title2)
        .fontWeight(.semibold)
        .tint(self.data.colors.callToActionBackgroundColor.gradient)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
    }

    private static let imageAspectRatio = 1.1

}

// MARK: -

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension Example1TemplateContent {

    struct Data {
        let package: Package
        let localization: ProcessedLocalizedConfiguration
        let configuration: PaywallData.Configuration
        let headerImageURL: URL
        let colors: PaywallData.Configuration.Colors
    }

    enum Error: Swift.Error {

        case noPackages
        case couldNotFindAnyPackages(expectedTypes: [PackageType])

    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension Example1TemplateContent.Error: CustomNSError {

    var errorUserInfo: [String: Any] {
        return [
            NSLocalizedDescriptionKey: self.description
        ]
    }

    private var description: String {
        switch self {
        case .noPackages:
            return "Attempted to display paywall with no packages."
        case let .couldNotFindAnyPackages(expectedTypes):
            return "Couldn't find any requested packages: \(expectedTypes)"
        }
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension View {

    func withPendingData(_ pending: Bool) -> some View {
        self
            .hidden(if: pending)
            .overlay {
                if pending {
                    ProgressView()
                }
            }
            .transition(.opacity.animation(Constants.defaultAnimation))
    }

}
