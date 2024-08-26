//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/12/24.
//

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {
    
    struct SpacerComponent: PaywallComponentBase {

        let type: String

        public init() {
            self.type = "spacer"
        }

    }

}

#endif
