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

    struct SpacerComponent: PaywallComponentBase {

        let type: ComponentType

        public init() {
            self.type = .spacer
        }

    }

}

#endif
