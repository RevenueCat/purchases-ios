//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendLanes.swift
//
//  Created by Antonio Pallares on 18/9/26.

import Foundation

/// Holds the `BackendConfiguration` for each request lane, falling back to the default lane's
/// configuration when a lane has no dedicated one.
final class BackendLanes: Sendable {

    private let defaultConfiguration: BackendConfiguration
    private let dedicatedConfigurations: [RequestLane: BackendConfiguration]

    init(configuration: BackendConfiguration) {
        self.defaultConfiguration = configuration
        self.dedicatedConfigurations = [:]
    }

    init(defaultConfiguration: BackendConfiguration,
         dedicatedConfigurations: [RequestLane: BackendConfiguration]) {
        self.defaultConfiguration = defaultConfiguration
        self.dedicatedConfigurations = dedicatedConfigurations
    }

    subscript(lane: RequestLane) -> BackendConfiguration {
        return self.dedicatedConfigurations[lane] ?? self.defaultConfiguration
    }

    func clearHTTPClientCaches() {
        self.defaultConfiguration.clearCache()
        for configuration in self.dedicatedConfigurations.values {
            configuration.clearCache()
        }
    }

}

/// Builds one `BackendConfiguration` per lane — each with its own `HTTPClient` and `OperationQueue` —
/// while collaborators that must stay shared across lanes remain shared, so adding a lane costs one
/// entry in `dedicatedLanes`.
struct BackendLanesFactory {

    let systemInfo: SystemInfo
    let eTagManager: ETagManager
    let tokenManager: TokenManager
    let diagnosticsTracker: DiagnosticsTrackerType?
    let networkTimeout: NetworkTimeout
    let apiSourceFailover: APISourceFailoverType?
    let timeoutManager: HTTPRequestTimeoutManagerType
    let operationDispatcher: OperationDispatcher
    let offlineCustomerInfoCreator: OfflineCustomerInfoCreator?
    let dateProvider: DateProvider

    /// - Parameter dedicatedLanes: lanes that get their own `HTTPClient` and `OperationQueue`.
    ///   Any lane not listed runs on the default lane.
    func makeLanes(dedicatedLanes: Set<RequestLane>) -> BackendLanes {
        let diagnosticsQueue = Backend.QueueProvider.createDiagnosticsQueue()
        let defaultConfiguration = self.makeConfiguration(for: .default, diagnosticsQueue: diagnosticsQueue)

        // `.default` is always represented by `defaultConfiguration`; a dedicated entry would be unused.
        let lanesToCreate = dedicatedLanes.filter { $0 != .default }
        var dedicatedConfigurations: [RequestLane: BackendConfiguration] = [:]
        for lane in lanesToCreate {
            dedicatedConfigurations[lane] = self.makeConfiguration(for: lane, diagnosticsQueue: diagnosticsQueue)
        }

        return BackendLanes(defaultConfiguration: defaultConfiguration,
                            dedicatedConfigurations: dedicatedConfigurations)
    }

    private func makeConfiguration(for lane: RequestLane,
                                   diagnosticsQueue: OperationQueue) -> BackendConfiguration {
        // `timeoutManager` is shared by every lane's HTTPClient (and, outside of `Backend`, by the blob
        // downloader) so a timeout one of them sees on a host fast-fails the others' next request to that
        // same host, and a success on any of them clears it for all.
        let httpClient = HTTPClient(systemInfo: self.systemInfo,
                                    eTagManager: self.eTagManager,
                                    tokenManager: self.tokenManager,
                                    signing: Signing(apiKey: self.systemInfo.apiKey, clock: self.systemInfo.clock),
                                    diagnosticsTracker: self.diagnosticsTracker,
                                    networkTimeout: self.networkTimeout,
                                    operationDispatcher: OperationDispatcher.default,
                                    apiSourceFailover: self.apiSourceFailover,
                                    timeoutManager: self.timeoutManager)
        return BackendConfiguration(httpClient: httpClient,
                                    operationDispatcher: self.operationDispatcher,
                                    operationQueue: Backend.QueueProvider.createQueue(for: lane),
                                    diagnosticsQueue: diagnosticsQueue,
                                    systemInfo: self.systemInfo,
                                    offlineCustomerInfoCreator: self.offlineCustomerInfoCreator,
                                    dateProvider: self.dateProvider)
    }

}
