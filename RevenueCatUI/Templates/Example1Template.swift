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

            IntroEligibilityStateView(
                textWithNoIntroOffer: self.localization.offerDetails,
                textWithIntroOffer: self.localization.offerDetailsWithIntroOffer,
                introEligibility: self.introEligibility
            )
            .font(self.configuration.mode.offerDetailsFont)
            .foregroundColor(self.configuration.colors.text1Color)

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

        case .card:
            self.asyncImage
                .clipShape(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                )

            Spacer()

        case .banner:
            EmptyView()
        }
    }

    @ViewBuilder
    private var button: some View {
        PurchaseButton(
            package: self.configuration.packages.single.content,
            purchaseHandler: self.purchaseHandler,
            colors: self.configuration.colors,
            localization: self.localization,
            introEligibility: self.introEligibility,
            mode: self.configuration.mode
        )
    }

    private static let imageAspectRatio = 1.1

}

// MARK: - Extensions

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension PaywallViewMode {

    var verticalSpacing: CGFloat? {
        switch self {
        case .fullScreen, .card: return nil // Default value
        case .banner: return 4
        }
    }

    var titleFont: Font {
        switch self {
        case .fullScreen: return .largeTitle
        case .card: return .title
        case .banner: return .headline
        }
    }

    var subtitleFont: Font {
        switch self {
        case .fullScreen: return .subheadline
        case .card, .banner: return .callout
        }
    }

    var displaySubtitle: Bool {
        switch self {
        case .fullScreen, .card: return true
        case .banner: return false
        }
    }

    var offerDetailsFont: Font {
        switch self {
        case .fullScreen: return .callout
        case .card, .banner: return .caption
        }
    }

}
