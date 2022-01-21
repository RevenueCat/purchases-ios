//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NetworkOperation.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

class CacheableNetworkOperation: NetworkOperation, Cachable {

    var key: String { "\(Self.description()) \(individualizedCacheKeyPart)" }

    let individualizedCacheKeyPart: String

    init(configuration: NetworkConfiguration, individualizedCacheKeyPart: String) {
        self.individualizedCacheKeyPart = individualizedCacheKeyPart

        super.init(configuration: configuration)
    }

}

class NetworkOperation: Operation {

    let httpClient: HTTPClient
    let authHeaders: [String: String]

    init(configuration: NetworkConfiguration) {
        self.httpClient = configuration.httpClient
        self.authHeaders = configuration.authHeaders

        super.init()
    }

    override func main() {
        fatalError("Subclasses must override this method")
    }

    struct Configuration: NetworkConfiguration {

        let httpClient: HTTPClient
        let authHeaders: [String: String]

    }

    struct UserSpecificConfiguration: AppUserConfiguration, NetworkConfiguration {

        let httpClient: HTTPClient
        let authHeaders: [String: String]
        let appUserID: String

    }

}

protocol AppUserConfiguration {

    var appUserID: String { get }

}

protocol NetworkConfiguration {

    var httpClient: HTTPClient { get }
    var authHeaders: [String: String] { get }

}
