//
//  AttributionAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 5/25/23.
//

import RevenueCat_CustomEntitlementComputation

private var attribution: Attribution!

func checkAttributionAPI() {
    if #available(iOS 14.3, *) {
        attribution.enableAdServicesAttributionTokenCollection()
    }
}
