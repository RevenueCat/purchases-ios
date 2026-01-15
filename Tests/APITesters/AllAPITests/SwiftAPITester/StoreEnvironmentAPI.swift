//
//  StoreEnvironmentAPI.swift
//  APITesters
//
//  Created by Rick van der Linden on 15/01/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import RevenueCat

func checkStoreEnvironmentEnum(_ storeEnvironment: StoreEnvironment) {
    switch storeEnvironment {
    case .production: break
    case .sandbox: break
    case .xcode: break
    @unknown default: break
    }
}
