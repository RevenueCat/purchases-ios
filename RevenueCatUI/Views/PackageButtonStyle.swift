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
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct PackageButtonStyle: ButtonStyle {

    var isSelected: Bool

    @Environment(\.isEnabled)
    private var isEnabled

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration
            .label
            .hidden(if: !self.isEnabled)
            .overlay {
                if self.isSelected, !self.isEnabled {
                    ProgressView()
                }
            }
    }

}
