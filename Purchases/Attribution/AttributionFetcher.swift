//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AttributionFetcher.swift
//
//  Created by Andrés Boedo on 4/8/21.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

enum AttributionFetcherError: Error {

    case identifierForAdvertiserUnavailableForPlatform
    case identifierForAdvertiserFrameworksUnavailable

}

class AttributionFetcher {

    private let attributionFactory: AttributionTypeFactory
    private let systemInfo: SystemInfo

#if os(watchOS) || os(macOS) || targetEnvironment(macCatalyst)
    private let appTrackingTransparencyRequired = false
#else
    private let appTrackingTransparencyRequired = true
#endif

    init(attributionFactory: AttributionTypeFactory, systemInfo: SystemInfo) {
        self.attributionFactory = attributionFactory
        self.systemInfo = systemInfo
    }

    var identifierForVendor: String? {
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

    var identifierForAdvertisers: String? {
        // should match available platforms here:
        // https://developer.apple.com/documentation/adsupport/asidentifiermanager/1614151-advertisingidentifier
#if os(iOS) || os(tvOS) || os(macOS)
        if #available(macOS 10.14, *) {
            let maybeIdentifierManagerProxy = attributionFactory.asIdProxy()
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

    func afficheClientAttributionDetails(completion: @escaping ([String: NSObject]?, Error?) -> Void) {
        // Should match available platforms in
        // https://developer.apple.com/documentation/iad/adclient?language=swift
#if os(iOS)
        guard let afficheClientProxy = attributionFactory.afficheClientProxy() else {
            Logger.warn(Strings.attribution.search_ads_attribution_cancelled_missing_ad_framework)
            completion(nil, AttributionFetcherError.identifierForAdvertiserFrameworksUnavailable)
            return
        }
        afficheClientProxy.requestAttributionDetails(completion)
#else
        completion(nil, AttributionFetcherError.identifierForAdvertiserUnavailableForPlatform)
#endif
    }

    var isAuthorizedToPostSearchAds: Bool {
        // Should match platforms that require permissions detailed in
        // https://developer.apple.com/app-store/user-privacy-and-data-use/
        if !appTrackingTransparencyRequired {
            return true
        }

        if #available(iOS 14.0.0, tvOS 14.0.0, *) {
            return isAuthorizedToPostSearchAdsInATTRequiredOS
        }

        return true
    }

}

private extension AttributionFetcher {

    @available(iOS 14.0.0, tvOS 14.0.0, *)
    private var isAuthorizedToPostSearchAdsInATTRequiredOS: Bool {
        let minimumOSVersionRequiringAuthorization = OperatingSystemVersion(majorVersion: 14,
                                                                            minorVersion: 5,
                                                                            patchVersion: 0)
        let needsTrackingAuthorization = systemInfo
            .isOperatingSystemAtLeastVersion(minimumOSVersionRequiringAuthorization)

        guard let trackingManagerProxy = attributionFactory.atFollowingProxy() else {
            if needsTrackingAuthorization {
                Logger.warn(Strings.attribution.search_ads_attribution_cancelled_missing_att_framework)
            }
            return !needsTrackingAuthorization
        }

        let authStatusSelector = NSSelectorFromString(trackingManagerProxy.authorizationStatusPropertyName)
        guard trackingManagerProxy.responds(to: authStatusSelector) else {
            Logger.warn(Strings.attribution.att_framework_present_but_couldnt_call_tracking_authorization_status)
            return false
        }

        // we use unsafeBitCast to prevent direct references to tracking frameworks, which cause issues for
        // kids apps when going through app review, even if they don't actually use them at all.
        typealias ClosureType = @convention(c) (AnyObject, Selector) -> FakeTrackingManagerAuthorizationStatus
        let authStatusMethodImplementation = trackingManagerProxy.method(for: authStatusSelector)
        let authStatusMethod: ClosureType = unsafeBitCast(authStatusMethodImplementation, to: ClosureType.self)
        let authStatus = authStatusMethod(trackingManagerProxy, authStatusSelector)

        switch authStatus {
        case .restricted, .denied:
            return false
        case .notDetermined:
            return !needsTrackingAuthorization
        case .authorized:
            return true
        }
    }

}
