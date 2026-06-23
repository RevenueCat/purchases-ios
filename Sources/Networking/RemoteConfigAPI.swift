//
//  RemoteConfigAPI.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol RemoteConfigAPIType: AnyObject {

    typealias RemoteConfigResponseHandler = Backend.ResponseHandler<RemoteConfigFetchResult>

    func getRemoteConfig(
        request: RemoteConfigRequest,
        isAppBackgrounded: Bool,
        completion: @escaping RemoteConfigResponseHandler
    )

}

class RemoteConfigAPI: RemoteConfigAPIType {

    typealias RemoteConfigResponseHandler = Backend.ResponseHandler<RemoteConfigFetchResult>

    private let callbackCache: CallbackCache<RemoteConfigCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.callbackCache = .init()
    }

    func getRemoteConfig(
        request: RemoteConfigRequest = .init(),
        isAppBackgrounded: Bool,
        completion: @escaping RemoteConfigResponseHandler
    ) {
        let factory = GetRemoteConfigOperation.createFactory(
            configuration: self.backendConfig,
            callbackCache: self.callbackCache,
            request: request
        )

        let callback = RemoteConfigCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.callbackCache.add(callback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .default(forBackgroundedApp: isAppBackgrounded),
            cacheStatus: cacheStatus
        )
    }

}

enum RemoteConfigFetchResult {

    case container(RemoteConfigContainer, verificationResult: VerificationResult)
    case noContent(verificationResult: VerificationResult)

    var container: RemoteConfigContainer? {
        switch self {
        case let .container(container, _):
            return container
        case .noContent:
            return nil
        }
    }

    var verificationResult: VerificationResult {
        switch self {
        case let .container(_, verificationResult),
             let .noContent(verificationResult):
            return verificationResult
        }
    }

    init(response: VerifiedHTTPResponse<Data?>) throws {
        if let body = response.body {
            self = try .container(
                RemoteConfigContainer(data: body),
                verificationResult: response.verificationResult
            )
        } else {
            self = .noContent(verificationResult: response.verificationResult)
        }
    }

}

struct RemoteConfigContainer {

    /// Underlying generic RC Container parsed from the remote config response.
    let rcContainer: RCContainer

    /// The first RC Container element, interpreted as the remote config payload for `/v2/config`.
    let configElement: RCContainer.Element

    /// Inline blob elements delivered with the remote config response, keyed by stored checksum.
    let inlineContentElements: [String: RCContainer.Element]

    /// Parses a remote config response container and validates the required config element.
    ///
    /// Inline content elements are opportunistic cache entries and are validated only when they are
    /// written to the blob store.
    init(data: Data) throws {
        let container = try RCContainer(data: data)
        try self.init(rcContainer: container)
    }

    init(rcContainer container: RCContainer) throws {
        let configElement = try Self.validatedConfigElement(in: container)

        self.rcContainer = container
        self.configElement = configElement
        self.inlineContentElements = Dictionary(
            container.elements.dropFirst().map { ($0.checksum, $0) },
            uniquingKeysWith: { _, last in last }
        )
    }

}

extension RemoteConfigContainer {

    /// Parses only the first RC Container element, which remote config defines as the config element.
    ///
    /// This avoids parsing the whole container when signature verification only needs the config
    /// checksum.
    static func validatedConfigElement(from data: Data) throws -> RCContainer.Element {
        var parser = RCContainer.ElementParser(data: data)
        try parser.moveToFirstElement()
        guard parser.hasRemainingBytes else {
            throw RCContainer.Parser.FormatError.missingElement(index: 0)
        }

        return try self.validatedConfigElement(parser.parseElement(index: 0))
    }

    static func validatedConfigElement(in container: RCContainer) throws -> RCContainer.Element {
        guard let configElement = container.elements.first else {
            throw RCContainer.Parser.FormatError.missingElement(index: 0)
        }

        return try self.validatedConfigElement(configElement)
    }

    private static func validatedConfigElement(_ element: RCContainer.Element) throws -> RCContainer.Element {
        try element.validateChecksum()
        return element
    }

}
