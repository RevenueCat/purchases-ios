//
//  PackageViewModel.swift
//  SampleCat
//
//  Created by Hidde van der Ploeg on 7/4/25.
//
import SwiftUI
import RevenueCat

struct PackageViewModel: Identifiable, Equatable {
    var id: String { identifier }
    let identifier: String
    let productIdentifier: String
    let title: String
    let price: String?
    let status: AppHealthResponse.AppHealthOffering.AppHealthStatus
    let statusHelperText: String
    
    init(
        identifier: String,
        productIdentifier: String,
        title: String,
        price: String?,
        status: AppHealthResponse.AppHealthOffering.AppHealthStatus,
        statusHelperText: String
    ) {
        self.identifier = identifier
        self.productIdentifier = productIdentifier
        self.title = title
        self.price = price
        self.status = status
        self.statusHelperText = Self.generateStatusText(from: statusHelperText, andStatus: status)
    }
    
    private static func generateStatusText(from helperText: String, andStatus status: AppHealthResponse.AppHealthOffering.AppHealthStatus) -> String {
        switch status {
        case .ok: "Ready for production purchases."
        case .couldNotCheck: helperText
        case .notFound: "Product not found in App Store Connect."
        case .actionInProgress: "Product found with state: '\(helperText)'."
        case .needsAction: "Product found with state: \(helperText)."
        case .unknown: helperText
        }
    }
}
