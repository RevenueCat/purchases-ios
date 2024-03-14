//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SwiftVersionCheck.swift
//
//  Created by Nacho Soto on 1/18/23.

import Foundation

#if swift(<5.7)
// See https://xcodereleases.com and https://swiftversion.net
#error("RevenueCat requires Xcode 14.0 with Swift 5.7 to compile.")
#endif
