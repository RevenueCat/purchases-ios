//
//  AttributionAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 5/25/23.
//

import RevenueCat_CustomEntitlementComputation

private var attribution: Attribution!

func checkAttributionAPI() {
    #if os(iOS) || os(macOS)
    if #available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *) {
        attribution.enableAdServicesAttributionTokenCollection()
    }
    #endif
}
