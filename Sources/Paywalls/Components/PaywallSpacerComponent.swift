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

    public let selectedComponent: SpacerComponent?

    struct SpacerComponent: PaywallComponentBase {

        let type: ComponentType

        public init(selectedComponent: SpacerComponent? = nil) {
            self.type = .spacer
            self.selectedComponent = selectedComponent
        }

    }

}

#endif
