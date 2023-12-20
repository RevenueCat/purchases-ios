//
//  StoreKitVersionAPI.swift
//  SwiftAPITester
//
//  Created by Mark Villacampa on 20/12/23.
//

import Foundation
import RevenueCat

func checkStoreKitVersionAPI(_ version: StoreKitVersion = .default) {

    let _: String = version.debugDescription

    switch version {
    case .storeKit1, .storeKit2:
        break
    @unknown default:
        break
    }
}
