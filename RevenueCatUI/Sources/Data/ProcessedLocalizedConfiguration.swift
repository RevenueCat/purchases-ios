//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProcessedLocalizedConfiguration.swift

import Foundation
import RevenueCat

/// A `PaywallData.LocalizedConfiguration` with processed variables
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ProcessedLocalizedConfiguration: PaywallLocalizedConfiguration {

    typealias Feature = PaywallData.LocalizedConfiguration.Feature

    var title: String
    var subtitle: String?
    var callToAction: String
    var callToActionWithIntroOffer: String?
    var offerDetails: String?
    var offerDetailsWithIntroOffer: String?
    var offerName: String?
    var features: [Feature]

    init(
        _ configuration: PaywallData.LocalizedConfiguration,
        _ dataProvider: VariableDataProvider,
        _ context: VariableHandler.Context,
        _ locale: Locale
    ) {
        self.init(
            title: configuration.title.processed(with: dataProvider, context: context, locale: locale),
            subtitle: configuration.subtitle?.processed(with: dataProvider, context: context, locale: locale),
            callToAction: configuration.callToAction.processed(with: dataProvider, context: context, locale: locale),
            callToActionWithIntroOffer: configuration.callToActionWithIntroOffer?.processed(with: dataProvider,
                                                                                            context: context,
                                                                                            locale: locale),
            offerDetails: configuration.offerDetails?.processed(with: dataProvider, context: context, locale: locale),
            offerDetailsWithIntroOffer: configuration.offerDetailsWithIntroOffer?.processed(with: dataProvider,
                                                                                            context: context,
                                                                                            locale: locale),
            offerName: configuration.offerName?.processed(with: dataProvider, context: context, locale: locale),
            features: configuration.features.map {
                .init(title: $0.title.processed(with: dataProvider, context: context, locale: locale),
                      content: $0.content?.processed(with: dataProvider, context: context, locale: locale),
                      iconID: $0.iconID)
            }
        )
    }

    private init(
        title: String,
        subtitle: String?,
        callToAction: String,
        callToActionWithIntroOffer: String?,
        offerDetails: String?,
        offerDetailsWithIntroOffer: String?,
        offerName: String?,
        features: [Feature]
    ) {
        self.title = title
        self.subtitle = subtitle
        self.callToAction = callToAction
        self.callToActionWithIntroOffer = callToActionWithIntroOffer
        self.offerDetails = offerDetails
        self.offerDetailsWithIntroOffer = offerDetailsWithIntroOffer
        self.offerName = offerName
        self.features = features
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension ProcessedLocalizedConfiguration: Equatable {}
