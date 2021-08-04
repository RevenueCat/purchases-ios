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

    #if os(watchOS) || os(macOS) || targetEnvironment(macCatalyst)
    private let appTrackingTransparencyRequired = false
    #else
    private let appTrackingTransparencyRequired = true
    #endif

    @objc public var isAuthorizedToPostSearchAds: Bool {
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
        let needsTrackingAuthorization = systemInfo.isOperatingSystemAtLeastVersion(minimumOSVersionRequiringAuthorization)

        guard let trackingManagerProxy = attributionFactory.atTrackingProxy() else {
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
