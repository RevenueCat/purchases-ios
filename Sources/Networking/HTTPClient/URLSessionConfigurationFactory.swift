//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  URLSessionConfigurationFactory.swift
//
//  Created by Andrés Boedo on 5/29/23.

import Foundation

protocol URLSessionConfigurationFactoryType {
    func urlSessionConfiguration(requestTimeout: TimeInterval) -> URLSessionConfiguration
}

struct URLSessionConfigurationFactory: URLSessionConfigurationFactoryType {

    func urlSessionConfiguration(requestTimeout: TimeInterval) -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 1
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            config.requiresDNSSECValidation = true
        }
        return config
    }

}
