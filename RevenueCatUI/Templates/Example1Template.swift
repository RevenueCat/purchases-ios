import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct Example1Template: TemplateViewType {

    private let configuration: TemplateViewConfiguration

    @EnvironmentObject
    private var introEligibilityChecker: TrialOrIntroEligibilityChecker

    @State
    private var introEligibility: IntroEligibilityStatus?

    init(_ configuration: TemplateViewConfiguration) {
        self.configuration = configuration
    }

    var body: some View {
        Example1TemplateContent(configuration: self.configuration,
                                introEligibility: self.introEligibility)
        .task(id: self.package) {
            self.introEligibility = await self.introEligibilityChecker.eligibility(for: self.package)
        }
    }

    private var package: Package {
        return self.configuration.packages.single.content
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct Example1TemplateContent: View {

    private var configuration: TemplateViewConfiguration
    private var introEligibility: IntroEligibilityStatus?
    private var localization: ProcessedLocalizedConfiguration

    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler
    @Environment(\.dismiss)
    private var dismiss

    init(configuration: TemplateViewConfiguration, introEligibility: IntroEligibilityStatus?) {
        self.configuration = configuration
        self.introEligibility = introEligibility
        self.localization = configuration.packages.single.localization
    }

    var body: some View {
        VStack {
            ScrollView(.vertical) {
                VStack {
                    AsyncImage(
                        url: self.configuration.headerImageURL,
                        transaction: .init(animation: Constants.defaultAnimation)
                    ) { phase in
                        if let image = phase.image {
                            image
                                .fitToAspect(Self.imageAspectRatio, contentMode: .fill)
                        } else if let error = phase.error {
                            DebugErrorView("Error loading image from '\(self.configuration.headerImageURL)': \(error)",
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
                        Text(verbatim: self.localization.title)
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .padding(.bottom)

                        Text(verbatim: self.localization.subtitle)
                            .font(.subheadline)
                    }
                    .padding(.horizontal)
                }
                .foregroundColor(self.configuration.colors.foregroundColor)
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
        .background(self.configuration.colors.backgroundColor)
    }

    private var offerDetails: some View {
        let detailsWithIntroOffer = self.localization.offerDetailsWithIntroOffer

        func text() -> String {
            if let detailsWithIntroOffer = detailsWithIntroOffer, self.isEligibleForIntro {
                return detailsWithIntroOffer
            } else {
                return self.localization.offerDetails
            }
        }

        return Text(verbatim: text())
            // Hide until we've determined intro eligibility
            // only if there is a custom intro offer string.
            .withPendingData(self.needsToWaitForIntroEligibility(detailsWithIntroOffer != nil))
            .font(.callout)
    }

    private var ctaText: some View {
        let ctaWithIntroOffer = self.localization.callToActionWithIntroOffer

        func text() -> String {
            if let ctaWithIntroOffer = ctaWithIntroOffer, self.isEligibleForIntro {
                return ctaWithIntroOffer
            } else {
                return self.localization.callToAction
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
        let package = self.configuration.packages.single.content

        AsyncButton {
            let cancelled = try await self.purchaseHandler.purchase(package: package).userCancelled

            if !cancelled {
                await self.dismiss()
            }
        } label: {
            self.ctaText
                .foregroundColor(self.configuration.colors.callToActionForegroundColor)
                .frame(maxWidth: .infinity)
        }
        .font(.title2)
        .fontWeight(.semibold)
        .tint(self.configuration.colors.callToActionBackgroundColor.gradient)
        .buttonStyle(.borderedProminent)
        #if !os(macOS)
        .buttonBorderShape(.capsule)
        #endif
        .controlSize(.large)
    }

    private static let imageAspectRatio = 1.1

}

// MARK: -

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
