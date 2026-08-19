//
//  CustomerCenterUIKitView.swift
//  PaywallsTester
//
//  Created by Will Taylor on 12/6/24.
//

#if canImport(UIKit) && os(iOS)

import SwiftUI
import RevenueCat
import RevenueCatUI

/// Allows us to display the CustomerCenterViewController in a SwiftUI app
struct CustomerCenterUIKitView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> CustomerCenterViewController {
        CustomerCenterViewController(
            restoreStarted: {
                print("CustomerCenter (UIKit): restoreStarted")
            },
            restoreCompleted: { _ in
                print("CustomerCenter (UIKit): restoreCompleted")
            },
            restoreFailed: { error in
                print("CustomerCenter (UIKit): restoreFailed: \(error)")
            },
            showingManageSubscriptions: {
                print("CustomerCenter (UIKit): showingManageSubscriptions")
            },
            refundRequestStarted: { productId in
                print("CustomerCenter (UIKit): refundRequestStarted. ProductId: \(productId)")
            },
            refundRequestCompleted: { productId, status in
                print("CustomerCenter (UIKit): refundRequestCompleted. Status: \(status)")
            },
            feedbackSurveyCompleted: { surveyOptionID in
                print("CustomerCenter (UIKit): feedbackSurveyCompleted. Result: \(surveyOptionID)")
            },
            promotionalOfferSucceeded: { customerInfo, transaction, offerId in
                print("CustomerCenter (UIKit): promotionalOfferSucceeded. " +
                      "OfferId: \(offerId), " +
                      "TransactionId: \(transaction.transactionIdentifier), " +
                      "Entitlements: \(customerInfo.entitlements.active.keys.joined(separator: ", "))")
            }
        )
    }
    
    func updateUIViewController(_ uiViewController: CustomerCenterViewController, context: Context) {
        // No updates needed
    }
}

#endif
