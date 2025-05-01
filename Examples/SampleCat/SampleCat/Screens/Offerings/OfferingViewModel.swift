//
//  OfferingViewModel.swift
//  SampleCat
//
//  Created by Hidde van der Ploeg on 7/4/25.
//
import RevenueCat
import SwiftUI

struct OfferingViewModel: Identifiable, Equatable {
    var id: String { identifier }
    let identifier: String
    let status: PurchasesDiagnostics.SDKHealthCheckStatus
    let products: [ProductViewModel]

    var icon: String {
        status.icon
    }

    var color: Color {
        status.color
    }
}
