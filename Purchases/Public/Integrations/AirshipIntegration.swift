//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AirshipIntegration.swift
//
//  Created by Joshua Liebowitz on 11/21/21.

import Foundation

@objc public class AirshipIntegration: NSObject, Integration {

    public static var networkName = "Airship"
    public var attributeName = "$airshipChannelId"

    private let attributionSetter: SubscriberAttributionSetter
    private let appUserIdentifier: AppUserIdentifiable

    init(subscriberAttributionSetter: SubscriberAttributionSetter, appUserIdentifier: AppUserIdentifiable) {
        self.attributionSetter = subscriberAttributionSetter
        self.appUserIdentifier = appUserIdentifier
        super.init()
    }

    /**
     * Subscriber attribute associated with the Airship Channel ID for the user
     * Required for the RevenueCat Airship integration
     *
     * - Parameter airshipChannelID: nil will delete the subscriber attribute
     */
    @objc public func setAirshipChannelID(_ airshipChannelID: String?) {
        attributionSetter.setAttributionID(airshipChannelID,
                                           forIntegration: self,
                                           appUserID: self.appUserIdentifier.currentAppUserID)
    }

    public static func configure(subscriberAttributionSetter: SubscriberAttributionSetter,
                                 appUserIdentifier: AppUserIdentifiable) -> Integration {
        return AirshipIntegration(subscriberAttributionSetter: subscriberAttributionSetter,
                                  appUserIdentifier: appUserIdentifier)
    }

}
