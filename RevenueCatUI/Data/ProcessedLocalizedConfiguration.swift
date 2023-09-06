import Foundation
import RevenueCat

/// A `PaywallData.LocalizedConfiguration` with processed variables
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct ProcessedLocalizedConfiguration: PaywallLocalizedConfiguration {

    var title: String
    var subtitle: String
    var callToAction: String
    var callToActionWithIntroOffer: String?
    var offerDetails: String
    var offerDetailsWithIntroOffer: String?

    init(
        _ configuration: PaywallData.LocalizedConfiguration,
        _ dataProvider: VariableDataProvider,
        _ locale: Locale
    ) {
        self.init(
            title: configuration.title.processed(with: dataProvider, locale: locale),
            subtitle: configuration.subtitle.processed(with: dataProvider, locale: locale),
            callToAction: configuration.callToAction.processed(with: dataProvider, locale: locale),
            callToActionWithIntroOffer: configuration.callToActionWithIntroOffer?.processed(with: dataProvider,
                                                                                            locale: locale),
            offerDetails: configuration.offerDetails.processed(with: dataProvider, locale: locale),
            offerDetailsWithIntroOffer: configuration.offerDetailsWithIntroOffer?.processed(with: dataProvider,
                                                                                            locale: locale)
        )
    }

    private init(
        title: String,
        subtitle: String,
        callToAction: String,
        callToActionWithIntroOffer: String?,
        offerDetails: String,
        offerDetailsWithIntroOffer: String?
    ) {
        self.title = title
        self.subtitle = subtitle
        self.callToAction = callToAction
        self.callToActionWithIntroOffer = callToActionWithIntroOffer
        self.offerDetails = offerDetails
        self.offerDetailsWithIntroOffer = offerDetailsWithIntroOffer
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension ProcessedLocalizedConfiguration: Equatable {}
