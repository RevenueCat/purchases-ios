//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendTestInitializers.swift
//
//  Created by Antonio Pallares on 22/9/26.

import Foundation

@testable import RevenueCat

extension BackendLanes {

    convenience init(configuration: BackendConfiguration) {
        self.init(defaultConfiguration: configuration, dedicatedConfigurations: [:])
    }

}

extension Backend {

    convenience init(backendConfig: BackendConfiguration,
                     attributionFetcher: AttributionFetcher) {
        self.init(lanes: BackendLanes(configuration: backendConfig), attributionFetcher: attributionFetcher)
    }

}
