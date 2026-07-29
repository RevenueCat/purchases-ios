//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowScreenMapper.swift

@_spi(Internal) import RevenueCat

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum WorkflowScreenMapper {

    static func toPaywallComponents(
        screen: WorkflowScreen,
        uiConfig: UIConfig,
        paywallId: String? = nil
    ) -> Offering.PaywallComponents {
        let data = PaywallComponentsData(
            id: paywallId,
            templateName: screen.templateName,
            assetBaseURL: screen.assetBaseURL,
            componentsConfig: screen.componentsConfig,
            componentsLocalizations: screen.componentsLocalizations,
            revision: screen.revision,
            defaultLocaleIdentifier: screen.defaultLocale,
            exitOffers: screen.exitOffers
        )
        return .init(uiConfig: uiConfig, data: data)
    }

    /// A paywall is always one of a workflow's screens, so the step's offering is the one whose paywall
    /// id we need. Mirrors Android's `offering.paywall?.id ?: offering.paywallComponents?.data?.id`.
    static func paywallId(from offering: Offering) -> String? {
        offering.paywall?.id ?? offering.internalPaywallComponents?.data.id
    }

}

#endif
