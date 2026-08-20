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

#if swift(<5.8)
// See https://xcodereleases.com and https://swiftversion.net
#error("RevenueCat requires Xcode 14.3.1 with Swift 5.8 to compile.")
#endif

/// Temporary public API used to validate conditional `@nonexhaustive` support across CI toolchains.
/// This must not be included in a release.
#if compiler(>=6.2.3)
@nonexhaustive(warn)
#endif
public enum TemporaryNonExhaustiveEnum { // swiftlint:disable:this no_new_public_enums

    /// A known value used by the compatibility test.
    case known

}
