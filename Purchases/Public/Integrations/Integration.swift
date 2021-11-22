//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Integration.swift
//
//  Created by Joshua Liebowitz on 11/21/21.

import Foundation

/**
 * All 3rd party integrations must conform to this protocol.
 */
@objc public protocol Integration {

    /**
     * Human-readable name of the integration, e.g.: Airship
     */
    static var networkName: String { get }

    /**
     * Attribute key that the integration uses, e.g.: $airshipID
     */
    var attributeName: String { get }

    /**
     * Configure is automatically called at the appropriate time during Purchases initialization.
     */
    static func configure(subscriberAttributionSetter: SubscriberAttributionSetter,
                          appUserIdentifier: AppUserIdentifiable) -> Integration

}
