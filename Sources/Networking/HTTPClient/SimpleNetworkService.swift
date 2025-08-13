//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SimpleNetworkService.swift
//
//  Created by Jacob Zivan Rakidzich on 8/12/25.

import Foundation

/// A protocol representing a simple network service
public protocol SimpleNetworkService {
    /// Fetch data from the network
    /// - Parameter url: The URL to fetch data from
    /// - Returns: Data upon success
    func data(from url: URL) async throws -> Data
}
