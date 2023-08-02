import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct OnePackageStandardTemplate: TemplateViewType {

    private let configuration: TemplateViewConfiguration
    private var localization: ProcessedLocalizedConfiguration

    @EnvironmentObject
    private var introEligibilityViewModel: IntroEligibilityViewModel
    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    init(_ configuration: TemplateViewConfiguration) {
        self.configuration = configuration
        self.localization = configuration.packages.single.localization
    }

    var body: some View {
        VStack(spacing: self.configuration.mode.verticalSpacing) {
            self.scrollableContent
                .scrollableIfNecessary()
                .scrollContentBackground(.hidden)
                .scrollBounceBehaviorBasedOnSize()
                .scrollIndicators(.automatic)

            if case .fullScreen = self.configuration.mode {
                Spacer()
            }

            IntroEligibilityStateView(
                textWithNoIntroOffer: self.localization.offerDetails,
                textWithIntroOffer: self.localization.offerDetailsWithIntroOffer,
                introEligibility: self.introEligibility,
                foregroundColor: self.configuration.colors.text1Color
            )
            .font(self.configuration.mode.offerDetailsFont)
            .multilineTextAlignment(.center)

            self.button
                .padding(.horizontal)

            if case .fullScreen = self.configuration.mode {
                FooterView(configuration: self.configuration.configuration,
                           color: self.configuration.colors.callToActionBackgroundColor,
                           purchaseHandler: self.purchaseHandler)
            }
        }
    }

    @ViewBuilder
    private var scrollableContent: some View {
        VStack(spacing: self.configuration.mode.verticalSpacing) {
            self.headerImage

            Spacer()

            Group {
                Text(verbatim: self.localization.title)
                    .font(self.configuration.mode.titleFont)
                    .fontWeight(.heavy)
                    .padding(
                        self.configuration.mode.displaySubtitle
                            ? .bottom
                            : []
                    )

                if self.configuration.mode.displaySubtitle, let subtitle = self.localization.subtitle {
                    Text(verbatim: subtitle)
                        .font(self.configuration.mode.subtitleFont)
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .foregroundColor(self.configuration.colors.text1Color)
        .multilineTextAlignment(.center)
        .edgesIgnoringSafeArea(self.configuration.mode.isFullScreen ? .top : [])
    }

    @ViewBuilder
    private var asyncImage: some View {
        if let headerImage = self.configuration.headerImageURL {
            RemoteImage(url: headerImage, aspectRatio: Self.imageAspectRatio)
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
                        .offset(y: -120)
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
            colors: self.configuration.colors,
            localization: self.localization,
            introEligibility: self.introEligibility,
            mode: self.configuration.mode,
            purchaseHandler: self.purchaseHandler
        )
    }

    // MARK: -

    private var introEligibility: IntroEligibilityStatus? {
        return self.introEligibilityViewModel.singleEligibility
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

// MARK: -

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
struct OnePackageStandardTemplate_Previews: PreviewProvider {

    static var previews: some View {
        PreviewableTemplate(offering: TestData.offeringWithIntroOffer) {
            OnePackageStandardTemplate($0)
        }
    }

}

#endif
