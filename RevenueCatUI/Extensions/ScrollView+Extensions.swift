//
//  ScrollView+Extensions.swift
//  
//
//  Created by Nacho Soto on 7/17/23.
//

import Foundation
import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension View {

    @ViewBuilder
    func scrollBounceBehaviorBasedOnSize() -> some View {
        if #available(iOS 16.4, macOS 13.3, tvOS 16.4, watchOS 9.4, *) {
            self.scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }

}
