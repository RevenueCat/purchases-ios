//
//  URLUtilities.swift
//
//
//  Created by Cesar de la Vega on 28/5/24.
//

import Foundation

enum URLUtilities {

    static func createMailURL() -> URL? {
        let subject = "Support Request"
        let body = "Please describe your issue or question."
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // swiftlint:disable:next todo
        // TODO: make configurable
        let urlString = "mailto:support@revenuecat.com?subject=\(encodedSubject)&body=\(encodedBody)"
        return URL(string: urlString)
    }

}
