//
//  HTTPClient.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation

import OSLog


public final class HTTPClient {
    
    static let shared = HTTPClient(domain: URL(string: "https://api.revenuecat.com")!)

    private let domain: URL
    private let headers: [String: String]

    private init(
        domain: URL,
        headers: [String: String] = [:]
    ) {
        Self.log(.info, "Creating HTTPClient with domain: \(domain)")

        self.domain = domain
        self.headers = headers
    }

//    public static func createDefault() -> Self {
//        return self.init(domain: #URL("https://api.revenuecat.com"))
//    }

//    public static func withDemoCredentials(apiKey: String) -> Self {
//        return self.init(
//            domain: #URL("https://demo-api.revenuecat.com"),
//            headers: [
//                "Authorization": "Bearer \(apiKey)"
//            ]
//        )
//    }

    func perform<Response: Decodable>(_ request: HTTPRequest) async throws -> Response {
        let request = try request.build(
            domain: self.domain,
            headers: self.headers
        )

        Self.log(.info, request, "Starting")

        let (data, response) = try await self.session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.unrecognizedResponse(response)
        }

        let statusCode = httpResponse.httpStatusCode
        Self.log(.info, request, "Finished: \(statusCode.rawValue)")

        guard statusCode.isSuccessfulResponse else {
            if let error = statusCode.toError() {
                throw error
            }

            if let errorResponse = try? JSONDecoder.default.decode(ErrorResponse.self, from: data) {
                throw Error.errorResponse(statusCode,
                                          errorResponse.code, 
                                          errorResponse.originalCode,
                                          errorResponse.message)
            } else {
                throw Error.invalidResponse(httpResponse)
            }
        }

        try Task.checkCancellation()

        do {
            return try await Task.detached(priority: .utility) {
                try JSONDecoder.default.decode(Response.self, from: data)
            }.value
        } catch {
            throw Error.failedParsingResponse(
                error,
                json: String(data: data, encoding: .utf8)
            )
        }
    }

    func removeCookies() {
        self.session.configuration.httpCookieStorage?.removeCookies(since: .distantPast)
    }

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.httpShouldSetCookies = true
        configuration.httpCookieStorage = .sharedCookieStorage(
            forGroupContainerIdentifier: UserDefaults.sharedAppGroup
        )

        return URLSession(configuration: configuration)
    }()

}

extension HTTPClient {

    public enum Error: Swift.Error {

        case unrecognizedResponse(URLResponse)
        case invalidResponse(HTTPURLResponse)
        case errorResponse(HTTPStatusCode, BackendErrorCode, Int, String)
        case failedParsingResponse(Swift.Error, json: String?)
        case failedBuildingURL

        case notFound

    }

}

// MARK: - Private

private extension HTTPClient {

    static func log(_ level: OSLogType, _ request: URLRequest, _ message: String) {
        Self.log(
            level,
            "\(request.httpMethod ?? "") \(request.url?.absoluteString ?? ""): \(message)"
        )
    }

    static func log(_ level: OSLogType, _ message: String) {
        Self.logger.log(
            level: level,
            "\(message)"
        )
    }
    
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.revenuecat.PaywallsTester",
                                       category: "HTTPClient")

}

private extension HTTPRequest {

    func build(
        domain: URL,
        headers: [String: String]
    ) throws -> URLRequest {
        var request = URLRequest(url: try self.url(with: domain))
        request.httpMethod = self.method.name
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")

        if let body = try self.endpoint.body {
            request.httpBody = body
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }

        for (header, value) in headers {
            request.setValue(value, forHTTPHeaderField: header)
        }

        // TODO: add information about client

        return request
    }

    private func url(with domain: URL) throws -> URL {
        guard var components = URLComponents(
            url: self.endpoint.url(with: domain),
            resolvingAgainstBaseURL: false
        ) else {
            throw HTTPClient.Error.failedBuildingURL
        }

        if let parameters = self.endpoint.parameters, !parameters.isEmpty {
            components.queryItems = parameters
                .lazy
                .map { URLQueryItem(name: $0, value: $1) }
        }

        if let url = components.url {
            return url
        } else {
            throw HTTPClient.Error.failedBuildingURL
        }
    }

}

private extension HTTPEndpoint {

    func url(with domain: URL) -> URL {
        let baseURL = self.isInternal
            ? domain.appending(path: "internal")
            : domain

        return baseURL
            .appending(path: "v1")
            .appending(path: "developers")
            .appending(path: self.path)
    }

    private static let baseURL = URL(string: "https://api.revenuecat.com/v1/developers/")!
    private static let internalBaseURL = URL(string: "https://api.revenuecat.com/internal/v1/developers/")!

}

private extension HTTPURLResponse {

    var httpStatusCode: HTTPStatusCode { .init(rawValue: self.statusCode) }

}

private extension HTTPStatusCode {

    func toError() -> HTTPClient.Error? {
        switch self {
        case .notFoundError: return .notFound
        default: return nil
        }
    }

}

// MARK: -

extension HTTPClient.Error: LocalizedError {

    public var failureReason: String? {
        switch self {
        case let .errorResponse(_, _, code, message):
            return "Error \(code): \(message)"

        case .notFound:
            return "Page not found"

        default:
            return self.localizedDescription
        }
    }

}
