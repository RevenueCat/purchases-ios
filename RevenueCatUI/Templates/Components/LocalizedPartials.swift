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

import Foundation

#if PAYWALL_COMPONENTS

protocol LocalizedPartial {}

struct LocalizedStates<T: LocalizedPartial> {

    let selected: T?
    let introOffer: T?

}

struct LocalizedConditions<T: LocalizedPartial> {

    let compact: T?
    let medium: T?
    let expanded: T?

}

#endif
