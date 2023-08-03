//
//  PackageButtonStyle.swift
//  
//
//  Created by Nacho Soto on 7/29/23.
//

import SwiftUI

/// A `ButtonStyle` suitable to be used for a package selection button.
/// Features:
/// - Automatic handling of disabled state
/// - Replaces itself with a loading indicator if it's the selected package.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct PackageButtonStyle: ButtonStyle {

    var isSelected: Bool

    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration
            .label
            .hidden(if: self.purchaseHandler.actionInProgress)
            .overlay {
                if self.isSelected, self.purchaseHandler.actionInProgress {
                    ProgressView()
                }
            }
    }

}
