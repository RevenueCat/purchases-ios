//
//  ViewExtensions.swift
//  
//
//  Created by Nacho Soto on 7/13/23.
//

import Foundation
import SwiftUI

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
extension View {

    @ViewBuilder
    func hidden(if condition: Bool) -> some View {
        if condition {
            self.hidden()
        } else {
            self
        }
    }

    @ViewBuilder
    func scrollable(
        _ axes: Axis.Set = .vertical,
        if condition: Bool
    ) -> some View {
        if condition {
            ScrollView(axes) {
                self
            }
        } else {
            self
        }
    }

}
