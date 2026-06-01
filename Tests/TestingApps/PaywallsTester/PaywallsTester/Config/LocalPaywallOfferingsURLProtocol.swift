//
//  LocalPaywallOfferingsURLProtocol.swift
//  PaywallsTester
//
//  Created by RevenueCat on 5/21/26.
//

import Foundation
#if canImport(ObjectiveC)
import ObjectiveC.runtime
#endif

#if canImport(ObjectiveC) && (os(iOS) || targetEnvironment(macCatalyst))

enum LocalPaywallOfferingsInterceptor {

    static func install() {
        URLSessionConfiguration.enableLocalPaywallOfferingsInterception()
    }

}

final class LocalPaywallOfferingsURLProtocol: URLProtocol {

    private static let revenueCatPrimaryHost = "api.revenuecat.com"
    private static let revenueCatHostSuffix = ".revenuecat.com"

    override class func canInit(with request: URLRequest) -> Bool {
        return Self.shouldIntercept(request)
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.currentRequest ?? task.originalRequest else {
            return false
        }

        return Self.shouldIntercept(request)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        do {
            let payload = try LocalPaywallOfferingsResponseFactory.makeOfferingsResponseData(
                settings: LocalPaywallOfferingsOverrideStore.settings
            )
            let response = try Self.makeHTTPResponse(for: self.request.url)

            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: payload)
            self.client?.urlProtocolDidFinishLoading(self)

            if let url = self.request.url {
                print("Intercepted RevenueCat offerings request with local paywall JSON: \(url.absoluteString)")
            }
        } catch {
            self.client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

}

private extension LocalPaywallOfferingsURLProtocol {

    static func shouldIntercept(_ request: URLRequest) -> Bool {
        guard
            LocalPaywallOfferingsOverrideStore.isActive,
            (request.httpMethod ?? "GET").uppercased() == "GET",
            let url = request.url,
            let host = url.host?.lowercased()
        else {
            return false
        }

        let proxyHost = Constants.proxyURL.flatMap { URL(string: $0)?.host?.lowercased() }
        let isRevenueCatRequest = host == Self.revenueCatPrimaryHost
            || host.hasSuffix(Self.revenueCatHostSuffix)
            || proxyHost.map { host == $0 } ?? false
        let isOfferingsRequest = url.path.contains("/subscribers/") && url.path.contains("/offerings")

        return isRevenueCatRequest && isOfferingsRequest
    }

    static func makeHTTPResponse(for url: URL?) throws -> HTTPURLResponse {
        guard let url else {
            throw LocalPaywallOfferingsOverrideError.invalidRequestURL
        }

        guard let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": "application/json",
                "Cache-Control": "no-store"
            ]
        ) else {
            throw LocalPaywallOfferingsOverrideError.invalidResponse
        }

        return response
    }

}

private extension URLSessionConfiguration {

    static func enableLocalPaywallOfferingsInterception() {
        _ = Self.swizzleLocalPaywallOfferingsInterception
    }

    static let swizzleLocalPaywallOfferingsInterception: Void = {
        guard
            let defaultMethod = class_getClassMethod(
                URLSessionConfiguration.self,
                #selector(getter: URLSessionConfiguration.default)
            ),
            let swizzledDefaultMethod = class_getClassMethod(
                URLSessionConfiguration.self,
                #selector(getter: URLSessionConfiguration.paywallsTester_interceptedDefault)
            ),
            let ephemeralMethod = class_getClassMethod(
                URLSessionConfiguration.self,
                #selector(getter: URLSessionConfiguration.ephemeral)
            ),
            let swizzledEphemeralMethod = class_getClassMethod(
                URLSessionConfiguration.self,
                #selector(getter: URLSessionConfiguration.paywallsTester_interceptedEphemeral)
            )
        else {
            return
        }

        method_exchangeImplementations(defaultMethod, swizzledDefaultMethod)
        method_exchangeImplementations(ephemeralMethod, swizzledEphemeralMethod)
    }()

    @objc dynamic class var paywallsTester_interceptedDefault: URLSessionConfiguration {
        return Self.inject(LocalPaywallOfferingsURLProtocol.self, into: Self.paywallsTester_interceptedDefault)
    }

    @objc dynamic class var paywallsTester_interceptedEphemeral: URLSessionConfiguration {
        return Self.inject(LocalPaywallOfferingsURLProtocol.self, into: Self.paywallsTester_interceptedEphemeral)
    }

    static func inject(
        _ protocolClass: AnyClass,
        into configuration: URLSessionConfiguration
    ) -> URLSessionConfiguration {
        var protocolClasses = configuration.protocolClasses ?? []

        if !protocolClasses.contains(where: { ObjectIdentifier($0) == ObjectIdentifier(protocolClass) }) {
            protocolClasses.insert(protocolClass, at: 0)
        }

        configuration.protocolClasses = protocolClasses
        return configuration
    }

}

#endif
