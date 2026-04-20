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
        screen: WorkflowResponse.WorkflowScreen,
        uiConfig: UIConfig
    ) -> Offering.PaywallComponents {
        let data = PaywallComponentsData(
            templateName: screen.templateName,
            assetBaseURL: screen.assetBaseURL,
            componentsConfig: screen.componentsConfig,
            componentsLocalizations: screen.componentsLocalizations,
            revision: screen.revision,
            defaultLocaleIdentifier: screen.defaultLocale
        )
        return .init(uiConfig: uiConfig, data: data)
    }

}

#endif
