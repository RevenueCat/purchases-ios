//
//  PresentableNSError.swift
//  Magic Weather SwiftUI
//
//  Created by Mustapha Tarek Ben Lechhab on 2026-01-28.
//

import Foundation

struct PresentableNSError: LocalizedError {
    let nsError: NSError

    init(_ error: Error) {
        self.nsError = error as NSError
    }

    var errorDescription: String? {
        nsError.localizedDescription
    }
    
    var failureReason: String? {
        nsError.localizedFailureReason ?? (nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String)
    }
    
    var recoverySuggestion: String? {
        nsError.localizedRecoverySuggestion ?? (nsError.userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String)
    }
    
    var helpAnchor: String? {
        nsError.helpAnchor ?? (nsError.userInfo[NSHelpAnchorErrorKey] as? String)
    }
}
