//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdServicesAttributionPosterTests.swift
//
//  Created by Madeline Beyl on 6/7/22.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
class AdServicesAttributionPosterTests: BaseAttributionPosterTests {

#if canImport(AdServices)
    func testPostAdServicesTokenIfNeededSkipsIfAlreadySent() {
        backend.stubbedPostAdServicesTokenCompletionResult = .success(())

        attributionPoster.postAdServicesTokenIfNeeded()
        expect(self.backend.invokedPostAdServicesTokenCount) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
        expect(self.deviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentCount) == 1

        attributionPoster.postAdServicesTokenIfNeeded()
        expect(self.backend.invokedPostAdServicesTokenCount) == 1
        expect(self.deviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentCount) == 1
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
    }

    func testPostAdServicesTokenIfNeededSkipsIfNilToken() throws {
        backend.stubbedPostAdServicesTokenCompletionResult = .success(())

        attributionFetcher.adServicesTokenToReturn = nil
        attributionPoster.postAdServicesTokenIfNeeded()
        expect(self.backend.invokedPostAdServicesTokenCount) == 0
        expect(self.subscriberAttributesManager.invokedConvertAttributionDataAndSetCount) == 0
    }

    func testPostAdServicesTokenIfNeededDoesNotCacheOnAPIError() throws {
        let stubbedError: BackendError = .networkError(
            .errorResponse(.init(code: .invalidAPIKey, message: nil),
                           400)
        )

        backend.stubbedPostAdServicesTokenCompletionResult = .failure(stubbedError)

        attributionFetcher.adServicesTokenToReturn = nil
        attributionPoster.postAdServicesTokenIfNeeded()
        expect(self.deviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentCount) == 0
    }

#endif

}
