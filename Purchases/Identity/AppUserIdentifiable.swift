//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppUserIdentifiable.swift
//
//  Created by Joshua Liebowitz on 11/21/21.

import Foundation

/**
 * Classes that conform to this protocol can provide a `currentAppUserID` property.
 */
@objc public protocol AppUserIdentifiable {

    /**
     * The current appUserID that the implementing class manages.
     */
    var currentAppUserID: String { get }

}
