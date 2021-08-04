//
// Created by Andrés Boedo on 4/8/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

import UIKit

enum AttributionFetcherError: Error {

    case identifierForAdvertiserUnavailableForPlatform
    case identifierForAdvertiserFrameworksUnavailable

}


@objc(RCAttributionFetcher) public class AttributionFetcher: NSObject {
    private let attributionFactory: AttributionTypeFactory
    private let systemInfo: SystemInfo

    @objc public init(attributionFactory: AttributionTypeFactory, systemInfo: SystemInfo) {
        self.attributionFactory = attributionFactory
        self.systemInfo = systemInfo
    }

    @objc public var identifierForVendor: String? {
        // Should match available platforms in
        // https://developer.apple.com/documentation/uikit/uidevice?language=swift
        // https://developer.apple.com/documentation/watchkit/wkinterfacedevice?language=swift
        #if os(iOS) || os(tvOS)
            UIDevice.current.identifierForVendor?.uuidString
        #elseif os(watchOS)
            WKInterfaceDevice.current().identifierForVendor?.uuidString
        #else
            nil
        #endif
    }

    @objc public var identifierForAdvertisers: String? {
        // should match available platforms here:
        // https://developer.apple.com/documentation/adsupport/asidentifiermanager/1614151-advertisingidentifier
        #if os(iOS) || os(tvOS) || os(macOS)
        if #available(macOS 10.14, *) {
            let maybeIdentifierManagerProxy = attributionFactory.asIdentifierProxy()
            guard let identifierManagerProxy = maybeIdentifierManagerProxy else {
                Logger.warn(Strings.configure.adsupport_not_imported)
                return nil
            }

            guard let identifierValue = identifierManagerProxy.adsIdentifier else {
                return nil
            }

            return identifierValue.uuidString
        }
        #endif
        return nil
    }

    @objc public func adClientAttributionDetails(completion: @escaping ([String: NSObject]?, Error?) -> Void) {
        // Should match available platforms in
        // https://developer.apple.com/documentation/iad/adclient?language=swift
        #if os(iOS)
        guard let adClientProxy = attributionFactory.adClientProxy() else {
            Logger.warn(Strings.attribution.search_ads_attribution_cancelled_missing_iad_framework)
            completion(nil, AttributionFetcherError.identifierForAdvertiserFrameworksUnavailable)
            return
        }
        adClientProxy.requestAttributionDetails(completion)
        #else
        completion(nil, AttributionFetcherError.idfaUnavailableForPlatform)
        #endif
    }

    @objc public var isAuthorizedToPostSearchAds: Bool {
        return false
    }
}
