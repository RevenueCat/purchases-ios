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
        VStack(spacing: self.configuration.mode.verticalSpacing) {
            VStack(spacing: self.configuration.mode.verticalSpacing) {
                self.headerImage

                Group {
                    Text(verbatim: self.localization.title)
                        .font(self.configuration.mode.titleFont)
                        .fontWeight(.heavy)
                        .padding(
                            self.configuration.mode.displaySubtitle
                                ? .bottom
                                : []
                        )

                    if self.configuration.mode.displaySubtitle {
                        Text(verbatim: self.localization.subtitle)
                            .font(self.configuration.mode.subtitleFont)
                    }
                }
                .padding(.horizontal)
            }
            .foregroundColor(self.configuration.colors.foregroundColor)
            .multilineTextAlignment(.center)
            .scrollable(if: self.configuration.mode.isFullScreen)
            .scrollContentBackground(.hidden)
            .scrollBounceBehaviorBasedOnSize()
            .scrollIndicators(.automatic)
            .edgesIgnoringSafeArea(self.configuration.mode.isFullScreen ? .top : [])

            if case .fullScreen = self.configuration.mode {
                Spacer()
            }

            self.offerDetails
            self.button
                .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var asyncImage: some View {
        if let headerImage = self.configuration.imageURLs.first {
            AsyncImage(
                url: headerImage,
                transaction: .init(animation: Constants.defaultAnimation)
            ) { phase in
                if let image = phase.image {
                    image
                        .fitToAspect(Self.imageAspectRatio, contentMode: .fill)
                } else if let error = phase.error {
                    DebugErrorView("Error loading image from '\(headerImage)': \(error)",
                                   releaseBehavior: .emptyView)
                } else {
                    Rectangle()
                        .hidden()
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(Self.imageAspectRatio, contentMode: .fit)
        }
    }

    @ViewBuilder
    private var headerImage: some View {
        switch self.configuration.mode {
        case .fullScreen:
            self.asyncImage
                .clipShape(
                    Circle()
                        .offset(y: -140)
                        .scale(3.0)
                )
                .padding(.bottom)

            Spacer()

        case .square:
            self.asyncImage
                .clipShape(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                )

            Spacer()

        case .banner:
            EmptyView()
        }
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
            .font(self.configuration.mode.offerDetailsFont)
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

        AsyncButton { @MainActor in
            let cancelled = try await self.purchaseHandler.purchase(package: package).userCancelled

            if !cancelled {
                self.dismiss()
            }
        } label: {
            self.ctaText
                .foregroundColor(self.configuration.colors.callToActionForegroundColor)
                .frame(
                    maxWidth: self.configuration.mode.fullWidthButton
                       ? .infinity
                        : nil
                )
        }
        .font(self.configuration.mode.buttonFont)
        .fontWeight(.semibold)
        .tint(self.configuration.colors.callToActionBackgroundColor.gradient)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(self.configuration.mode.buttonBorderShape)
        .controlSize(self.configuration.mode.buttonSize)
        .frame(maxWidth: .infinity)
    }

    private static let imageAspectRatio = 1.1

}

// MARK: - Extensions

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension PaywallViewMode {

    var verticalSpacing: CGFloat? {
        switch self {
        case .fullScreen, .square: return nil // Default value
        case .banner: return 4
        }
    }

    var titleFont: Font {
        switch self {
        case .fullScreen: return .largeTitle
        case .square: return .title
        case .banner: return .headline
        }
    }

    var subtitleFont: Font {
        switch self {
        case .fullScreen: return .subheadline
        case .square, .banner: return .callout
        }
    }

    var displaySubtitle: Bool {
        switch self {
        case .fullScreen, .square: return true
        case .banner: return false
        }
    }

    var offerDetailsFont: Font {
        switch self {
        case .fullScreen: return .callout
        case .square, .banner: return .caption
        }
    }

    var buttonFont: Font {
        switch self {
        case .fullScreen, .square: return .title2
        case .banner: return .footnote
        }
    }

    var fullWidthButton: Bool {
        switch self {
        case .fullScreen, .square: return true
        case .banner: return false
        }
    }

    var buttonSize: ControlSize {
        switch self {
        case .fullScreen: return .large
        case .square: return .regular
        case .banner: return .small
        }
    }

    var buttonBorderShape: ButtonBorderShape {
        switch self {
        case .fullScreen: return .capsule
        case .square, .banner: return .roundedRectangle
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
