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

@objc(RCAttributionFetcher) public class AttributionFetcher: NSObject {
    private let attributionFactory: AttributionTypeFactory
    private let systemInfo: SystemInfo

    @objc public init(attributionFactory: AttributionTypeFactory, systemInfo: SystemInfo) {
        self.attributionFactory = attributionFactory
        self.systemInfo = systemInfo
    }

    @objc public var identifierForVendor: String? {
        #if os(iOS) || os(tvOS)
            UIDevice.current.identifierForVendor?.uuidString
        #elseif os(watchOS)
            WKInterfaceDevice.current().identifierForVendor?.uuidString
        #else
            nil
        #endif
    }

    @objc public var identifierForAdvertisers: String? {
        #if os(iOS) || os(tvOS) || os(macOS)
        if #available(macOS 10.14, *) {
            let maybeIdentifierManagerProxy: ASIdentifierManagerProxy? = self.attributionFactory.asIdentifierProxy()
            guard let identifierManagerProxy = maybeIdentifierManagerProxy else {
                Logger.warn(String(format: Strings.configure.adsupport_not_imported))
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
}
