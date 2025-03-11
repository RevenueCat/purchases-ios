//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CacheStatus.swift
//
//  Created by Toni Rico Diez on 10/3/25.

enum CacheStatus: String, Codable {
    case stale = "STALE"
    case notFound = "NOT_FOUND"
    case valid = "VALID"
}
