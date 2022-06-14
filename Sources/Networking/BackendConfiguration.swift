//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendConfiguration.swift
//
//  Created by Joshua Liebowitz on 6/13/22.

import Foundation

class BackendConfiguration {

    let httpClient: HTTPClient

    let callbackQueue: DispatchQueue
    let operationQueue: OperationQueue
    let dateProvider: DateProvider

    init(httpClient: HTTPClient,
         operationQueue: OperationQueue,
         callbackQueue: DispatchQueue = DispatchQueue(label: "Backend callbackQueue"),
         dateProvider: DateProvider = DateProvider()) {
        self.httpClient = httpClient
        self.operationQueue = operationQueue
        self.callbackQueue = callbackQueue
        self.dateProvider = dateProvider
    }

    func clearCache() {
        self.httpClient.clearCaches()
    }

}
