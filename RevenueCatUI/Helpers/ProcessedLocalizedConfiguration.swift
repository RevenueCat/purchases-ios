import RevenueCat

/// A `PaywallData.LocalizedConfiguration` with processed variables
struct ProcessedLocalizedConfiguration: PaywallLocalizedConfiguration {

    var title: String
    var subtitle: String
    var callToAction: String
    var offerDetails: String

    init(
        _ configuration: PaywallData.LocalizedConfiguration,
        _ dataProvider: VariableDataProvider
    ) {
        self.init(
            title: configuration.title.processed(with: dataProvider),
            subtitle: configuration.subtitle.processed(with: dataProvider),
            callToAction: configuration.callToAction.processed(with: dataProvider),
            offerDetails: configuration.offerDetails.processed(with: dataProvider)
        )
    }

    private init(title: String, subtitle: String, callToAction: String, offerDetails: String) {
        self.title = title
        self.subtitle = subtitle
        self.callToAction = callToAction
        self.offerDetails = offerDetails
    }

}
