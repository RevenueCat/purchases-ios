//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockURLSessionConfigurationFactory.swift
//
//  Created by Andrés Boedo on 5/29/23.

import Foundation
@testable import RevenueCat

class MockSessionFactory: URLSessionConfigurationFactoryType {
    var configurationCalled = false
    func urlSessionConfiguration(requestTimeout: TimeInterval) -> URLSessionConfiguration {
        self.configurationCalled = true
        return URLSessionConfiguration.ephemeral
    }
}
