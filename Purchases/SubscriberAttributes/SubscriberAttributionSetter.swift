//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriberAttributionSetter.swift
//
//  Created by Joshua Liebowitz on 11/21/21.

import Foundation

/**
 * Enables objects to receive attribution data.
 */
@objc public protocol SubscriberAttributionSetter {

    /**
     * Collect attributionID for a given integration.
     */
    func setAttributionID(_ attributionID: String?, forIntegration integration: Integration, appUserID: String)

}
