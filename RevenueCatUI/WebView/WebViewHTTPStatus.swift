//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  WebViewHTTPStatus.swift
//

import Foundation

enum WebViewHTTPStatus {

    // WebKit treats an HTTP 4xx/5xx as a *successful* navigation (the error body renders and `didFail*`
    // never fires), so a navigation response's status code is the only signal that the main document
    // actually failed to load. Sub-frame/sub-resource errors are ignored so a single failing asset
    // doesn't tear down the whole web view.
    static func isTerminalError(statusCode: Int, isMainFrame: Bool) -> Bool {
        return isMainFrame && statusCode >= 400
    }

}
