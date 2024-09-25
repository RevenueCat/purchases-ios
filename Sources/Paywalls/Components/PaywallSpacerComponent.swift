//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/12/24.
//

import Foundation
// swiftlint:disable missing_docs

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    final class SpacerComponent: PaywallComponentBase {

        let type: ComponentType

        public let selectedComponent: SpacerComponent?

        public init(selectedComponent: SpacerComponent? = nil) {
            self.type = .spacer
            self.selectedComponent = selectedComponent
        }

    }

}

extension PaywallComponent.SpacerComponent: Equatable, Hashable {

    public static func == (lhs: PaywallComponent.SpacerComponent, rhs: PaywallComponent.SpacerComponent) -> Bool {
        return lhs.type == rhs.type && lhs.selectedComponent == rhs.selectedComponent
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(selectedComponent)
    }

}

#endif
