import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
@available(tvOS, unavailable)
struct Template1View: TemplateViewType {

    let configuration: TemplateViewConfiguration
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
                .scrollBounceBehaviorBasedOnSize()

            if case .fullScreen = self.configuration.mode {
                Spacer()
            }

            IntroEligibilityStateView(
                textWithNoIntroOffer: self.localization.offerDetails,
                textWithIntroOffer: self.localization.offerDetailsWithIntroOffer,
                introEligibility: self.introEligibility,
                foregroundColor: self.configuration.colors.text1Color
            )
            .font(self.font(for: self.configuration.mode.offerDetailsFont))
            .multilineTextAlignment(.center)
            .padding(.horizontal)

            self.button
                .padding(.horizontal)

            if case .fullScreen = self.configuration.mode {
                FooterView(configuration: self.configuration,
                           purchaseHandler: self.purchaseHandler)
            }
        }
    }

    @ViewBuilder
    private var scrollableContent: some View {
        VStack(spacing: self.configuration.mode.verticalSpacing) {
            self.headerImage

            Group {
                Text(.init(self.localization.title))
                    .font(self.font(for: self.configuration.mode.titleFont))
                    .fontWeight(.heavy)
                    .padding(
                        self.configuration.mode.displaySubtitle
                            ? .bottom
                            : []
                    )

                if self.configuration.mode.displaySubtitle, let subtitle = self.localization.subtitle {
                    Text(.init(subtitle))
                        .font(self.font(for: self.configuration.mode.subtitleFont))
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
                .modifier(CircleMaskModifier())

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
            localization: self.localization,
            configuration: self.configuration,
            introEligibility: self.introEligibility,
            purchaseHandler: self.purchaseHandler
        )
    }

    // MARK: -

    private var introEligibility: IntroEligibilityStatus? {
        return self.introEligibilityViewModel.singleEligibility
    }

    private static let imageAspectRatio: CGFloat = 1.2

}

// MARK: - Extensions

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private extension PaywallViewMode {

    var verticalSpacing: CGFloat? {
        switch self {
        case .fullScreen, .card: return nil // Default value
        case .banner: return 4
        }
    }

    var titleFont: Font.TextStyle {
        switch self {
        case .fullScreen: return .largeTitle
        case .card: return .title
        case .banner: return .headline
        }
    }

    var subtitleFont: Font.TextStyle {
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

    var offerDetailsFont: Font.TextStyle {
        switch self {
        case .fullScreen: return .callout
        case .card, .banner: return .caption
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct CircleMaskModifier: ViewModifier {

    @State
    private var size: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .onSizeChange { self.size = $0 }
            .clipShape(
                Circle()
                    .scale(Self.circleScale)
                    .offset(y: self.circleOffset)
            )
    }

    private var aspectRatio: CGFloat {
        return self.size.width / self.size.height
    }

    private var circleOffset: CGFloat {
        return (((self.size.height * Self.circleScale) - self.size.height) / 2.0 * -1)
            .rounded(.down)
    }

    private static let circleScale: CGFloat = 3

}

// MARK: -

#if DEBUG

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(macCatalyst, unavailable)
struct Template1View_Previews: PreviewProvider {

    static var previews: some View {
        PreviewableTemplate(offering: TestData.offeringWithIntroOffer) {
            Template1View($0)
        }
    }

}

#endif
