//
//  AppHealth+Ext.swift
//  SampleCat
//
//  Created by Hidde van der Ploeg on 7/4/25.
//

import SwiftUI
import RevenueCat

extension AppHealthResponse.AppHealthOffering.AppHealthStatus {
    var color: Color {
        switch self {
        case .ok: .green
        case .couldNotCheck, .unknown: .gray
        case .notFound: .red
        case .needsAction, .actionInProgress: .yellow
        }
    }
    
    var icon: String {
        switch self {
        case .ok: "checkmark.circle.fill"
        case .couldNotCheck, .unknown: "questionmark.circle.fill"
        case .notFound: "xmark.circle.fill"
        case .actionInProgress, .needsAction: "exclamationmark.triangle.fill"
        }
    }
}
