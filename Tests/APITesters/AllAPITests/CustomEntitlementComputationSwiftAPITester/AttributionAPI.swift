//
//  AttributionAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 5/25/23.
//

import RevenueCat_CustomEntitlementComputation

private var attribution: Attribution!

func checkAttributionAPI() {
    attribution.enableAdServicesAttributionTokenCollection()
}
