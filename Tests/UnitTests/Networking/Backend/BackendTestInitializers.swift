//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendTestInitializers.swift
//
//  Created by Antonio Pallares on 22/9/26.

import Foundation

@testable import RevenueCat

extension BackendLanes {

    convenience init(configuration: BackendConfiguration) {
        self.init(defaultConfiguration: configuration, dedicatedConfigurations: [:])
    }

}

extension Backend {

    convenience init(lanes: BackendLanes, attributionFetcher: AttributionFetcher) {
        self.init(
            lanes: lanes,
            attributionFetcher: attributionFetcher,
            subscriberDimensionsStore: MockSubscriberDimensionsStore()
        )
    }

    convenience init(backendConfig: BackendConfiguration,
                     attributionFetcher: AttributionFetcher) {
        self.init(lanes: BackendLanes(configuration: backendConfig), attributionFetcher: attributionFetcher)
    }

}

extension CustomerAPI {

    convenience init(backendConfig: BackendConfiguration, attributionFetcher: AttributionFetcher) {
        self.init(
            backendConfig: backendConfig,
            attributionFetcher: attributionFetcher,
            subscriberDimensionsStore: MockSubscriberDimensionsStore()
        )
    }

}

extension PostReceiptDataOperation {

    static func createFactory(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>,
        offlineCustomerInfoCreator: OfflineCustomerInfoCreator?
    ) -> CacheableNetworkOperationFactory<PostReceiptDataOperation> {
        return Self.createFactory(
            configuration: configuration,
            postData: postData,
            customerInfoCallbackCache: customerInfoCallbackCache,
            offlineCustomerInfoCreator: offlineCustomerInfoCreator,
            subscriberDimensionsStore: MockSubscriberDimensionsStore()
        )
    }

}
