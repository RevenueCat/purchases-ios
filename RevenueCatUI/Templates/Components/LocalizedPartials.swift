//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalizedPartials.swift
//
//  Created by Josh Holtz on 10/27/24.
//
// swiftlint:disable missing_docs

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS

protocol LocalizedPartial {}

struct LocalizedOverrides<T: LocalizedPartial> {

    public let introOffer: LocalizedPartial?
    public let states: LocalizedStates<T>?
    public let conditions: LocalizedConditions<T>?

}

struct LocalizedStates<T: LocalizedPartial> {

    let selected: T?

}

struct LocalizedConditions<T: LocalizedPartial> {

    let compact: T?
    let medium: T?
    let expanded: T?

}

#endif
