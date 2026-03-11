//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IAMSession.swift
//
//  Created by RevenueCat.

import Foundation

/// Holds the tokens returned by the IAM authentication service.
struct IAMSession: Equatable {

    let accessToken: String?
    let refreshToken: String?
    let idToken: String?

}
