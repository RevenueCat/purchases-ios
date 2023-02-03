//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CallbackCacheStatus.swift
//
//  Created by Joshua Liebowitz on 11/17/21.

import Foundation

enum CallbackCacheStatus {

    /// When an array exists in the cache for a particular path, we add to it and return this value.
    case addedToExistingInFlightList

    /// When an array doesn't yet exist in the cache for a particular path, we create one, add to it
    /// and return this value.
    case firstCallbackAddedToList

}
