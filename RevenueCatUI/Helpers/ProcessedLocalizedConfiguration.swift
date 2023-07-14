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
        _ dataProvider: VariableDataProvider
    ) {
        self.init(
            title: configuration.title.processed(with: dataProvider),
            subtitle: configuration.subtitle.processed(with: dataProvider),
            callToAction: configuration.callToAction.processed(with: dataProvider),
            callToActionWithIntroOffer: configuration.callToActionWithIntroOffer?.processed(with: dataProvider),
            offerDetails: configuration.offerDetails.processed(with: dataProvider),
            offerDetailsWithIntroOffer: configuration.offerDetailsWithIntroOffer?.processed(with: dataProvider)
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
