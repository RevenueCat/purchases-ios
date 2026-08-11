//
//  URLMessage+Description.swift
//  RevenueCat
//
//  Created by Dave DeLong on 8/7/26.
//

#if DEBUG

import Foundation

extension URLRequest {

    private var sortedHeaders: [(String, String)] {
        guard let headers = allHTTPHeaderFields else { return [] }
        return headers.sorted(by: { $0.key < $1.key })
    }

    internal func httpDescription(maxBodySize: Int = 2048) -> String {
        var lines = [String]()
        lines.append("\(httpMethod ?? "GET") \(url?.absoluteString ?? "<none>")")
        for (key, value) in sortedHeaders {
            lines.append("\(key): \(value)")
        }
        if let body = self.httpBody, let str = String(bytes: body.prefix(maxBodySize), encoding: .utf8) {
            lines.append("")
            lines.append(str)
        }

        return lines.joined(separator: "\n")
    }

}

extension URLResponse {

    private var sortedHeaders: [(AnyHashable, Any)] {
        guard let http = self as? HTTPURLResponse else { return [] }
        let headers = http.allHeaderFields
        return headers.sorted(by: { $0.key.description < $1.key.description })
    }

    internal func httpDescription(with body: Data?, maxBodySize: Int = 2048) -> String {
        var lines = [String]()

        if let http = self as? HTTPURLResponse {
            lines.append("\(http.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: http.statusCode))")
            for (key, value) in sortedHeaders {
                lines.append("\(key): \(value)")
            }
        } else {
            lines.append("\(type(of: self))")
            lines.append("URL: \(url?.absoluteString ?? "<none>")")
            if let mimeType { lines.append("Mime-Type: \(mimeType)") }
            if expectedContentLength > 0 { lines.append("Expected-Content-Length: \(expectedContentLength)") }
            if let textEncodingName { lines.append("Text-Encoding-Name: \(textEncodingName)") }
            if let suggestedFilename { lines.append("Suggested-File-Name: \(suggestedFilename)") }
        }

        if let body, body.count > 0, let str = String(bytes: body.prefix(maxBodySize), encoding: .utf8) {
            lines.append("")
            lines.append(str)
        }

        return lines.joined(separator: "\n")
    }

}

#endif
