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

#if canImport(AdServices)
import AdServices
#endif

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
        return self.systemInfo.identifierForVendor
    }

    var identifierForAdvertisers: String? {
        // should match available platforms here:
        // https://developer.apple.com/documentation/adsupport/asidentifiermanager/1614151-advertisingidentifier
#if os(iOS) || os(tvOS) || os(macOS)
        if #available(macOS 10.14, *) {
            let identifierManagerProxy = attributionFactory.asIdProxy()
            guard let identifierManagerProxy = identifierManagerProxy else {
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

    func afficheClientAttributionDetails(completion: @escaping ([String: NSObject]?, Swift.Error?) -> Void) {
        // Should match available platforms in
        // https://developer.apple.com/documentation/iad/adclient?language=swift
#if os(iOS)
        guard let afficheClientProxy = attributionFactory.afficheClientProxy() else {
            Logger.warn(Strings.attribution.search_ads_attribution_cancelled_missing_ad_framework)
            completion(nil, Error.identifierForAdvertiserFrameworksUnavailable)
            return
        }
        afficheClientProxy.requestAttributionDetails(completion)
#else
        completion(nil, Error.identifierForAdvertiserUnavailableForPlatform)
#endif
    }

    // should match OS availability in https://developer.apple.com/documentation/ad_services
    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    var adServicesToken: String? {
#if canImport(AdServices)
        do {
            #if targetEnvironment(simulator)
                // See https://github.com/RevenueCat/purchases-ios/issues/2121
                Logger.appleWarning(Strings.attribution.adservices_token_unavailable_in_simulator)
                return nil
            #else
                return try AAAttribution.attributionToken()
            #endif
        } catch {
            let message = Strings.attribution.adservices_token_fetch_failed(error: error)
            Logger.appleWarning(message)
            return nil
        }
#else
        Logger.warn(Strings.attribution.adservices_not_supported)
        return nil
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

    var authorizationStatus: FakeTrackingManagerAuthorizationStatus {
        // should match OS availability here: https://rev.cat/app-tracking-transparency
        guard #available(iOS 14.0.0, tvOS 14.0.0, macOS 11.0.0, *) else {
            return .notDetermined
        }
        return self.fetchAuthorizationStatus
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension AttributionFetcher: @unchecked Sendable {}

// MARK: - Private

private extension AttributionFetcher {

    enum Error: Swift.Error {

        case identifierForAdvertiserUnavailableForPlatform
        case identifierForAdvertiserFrameworksUnavailable

    }

}

private extension AttributionFetcher {

    @available(iOS 14.0.0, tvOS 14.0.0, *)
    private var isAuthorizedToPostSearchAdsInATTRequiredOS: Bool {
        let needsTrackingAuthorization = self.needsTrackingAuthorization

        guard let trackingManagerProxy = self.trackingProxy else {
            return !needsTrackingAuthorization
        }

        let authStatusSelector = NSSelectorFromString(trackingManagerProxy.authorizationStatusPropertyName)
        guard trackingManagerProxy.responds(to: authStatusSelector) else {
            Logger.warn(Strings.attribution.att_framework_present_but_couldnt_call_tracking_authorization_status)
            return false
        }

        let authStatus = callAuthStatusSelector(authStatusSelector, trackingManagerProxy: trackingManagerProxy)

        switch authStatus {
        case .restricted, .denied:
            return false
        case .notDetermined:
            return !needsTrackingAuthorization
        case .authorized:
            return true
        }
    }

    @available(iOS 14.0.0, tvOS 14.0.0, *)
    private var fetchAuthorizationStatus: FakeTrackingManagerAuthorizationStatus {
        let needsTrackingAuthorization = self.needsTrackingAuthorization

        guard let trackingManagerProxy = self.trackingProxy else {
            if needsTrackingAuthorization {
                return .denied
            } else {
                return .notDetermined
            }
        }

        let authStatusSelector = NSSelectorFromString(trackingManagerProxy.authorizationStatusPropertyName)
        guard trackingManagerProxy.responds(to: authStatusSelector) else {
            Logger.warn(Strings.attribution.att_framework_present_but_couldnt_call_tracking_authorization_status)
            return .denied
        }

        let authStatus = callAuthStatusSelector(authStatusSelector, trackingManagerProxy: trackingManagerProxy)
        return authStatus
    }

    private var trackingProxy: TrackingManagerProxy? {
        let trackingManagerProxy = attributionFactory.atFollowingProxy()
        if trackingManagerProxy == nil && needsTrackingAuthorization {
            Logger.warn(Strings.attribution.search_ads_attribution_cancelled_missing_att_framework)
        }
        return trackingManagerProxy
    }

    private var needsTrackingAuthorization: Bool {
        let minimumOSVersionRequiringAuthorization = OperatingSystemVersion(majorVersion: 14,
                                                                            minorVersion: 5,
                                                                            patchVersion: 0)
        return systemInfo.isOperatingSystemAtLeast(minimumOSVersionRequiringAuthorization)
    }

    private func callAuthStatusSelector(
        _ authStatusSelector: Selector,
        trackingManagerProxy: TrackingManagerProxy
    ) -> FakeTrackingManagerAuthorizationStatus {
        // we use unsafeBitCast to prevent direct references to tracking frameworks, which cause issues for
        // kids apps when going through app review, even if they don't actually use them at all.
        typealias ClosureType = @convention(c) (AnyObject, Selector) -> FakeTrackingManagerAuthorizationStatus
        let authStatusMethodImplementation = trackingManagerProxy.method(for: authStatusSelector)
        let authStatusMethod: ClosureType = unsafeBitCast(authStatusMethodImplementation, to: ClosureType.self)
        let authStatus = authStatusMethod(trackingManagerProxy, authStatusSelector)
        return authStatus
    }

}
