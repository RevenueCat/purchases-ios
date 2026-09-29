//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  WebViewNavigationFailure.swift
//

import Foundation

enum WebViewNavigationFailure {

    // A navigation we cancelled on purpose comes back through the same `didFail` callbacks as a real
    // failure, so every web view that returns `.cancel` from a navigation policy has to filter these
    // out before treating an error as a broken page.
    static func isCancellation(_ error: Error) -> Bool {
        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
            return true
        }

        // Cancelling from `decidePolicyFor` also surfaces as WebKitErrorDomain 102, "frame load
        // interrupted by a policy change".
        return nsError.domain == "WebKitErrorDomain" && nsError.code == 102
    }

}
