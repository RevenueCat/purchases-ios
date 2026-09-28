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

    let defaultConfiguration: BackendConfiguration
    private let dedicatedConfigurations: [RequestLane: BackendConfiguration]

    init(defaultConfiguration: BackendConfiguration,
         dedicatedConfigurations: [RequestLane: BackendConfiguration]) {
        self.defaultConfiguration = defaultConfiguration
        self.dedicatedConfigurations = dedicatedConfigurations
    }

    private subscript(lane: RequestLane) -> BackendConfiguration {
        if let configuration = self.dedicatedConfigurations[lane] {
            return configuration
        }

        // Single-lane bundles have an empty dedicated set by design, so every lane lookup
        // intentionally shares defaultConfiguration and should stay silent.
        if lane != .default && !self.dedicatedConfigurations.isEmpty {
            Logger.warn(Strings.network.missing_dedicated_lane_configuration(laneName: lane.name))
        }

        return self.defaultConfiguration
    }

    subscript<Operation: LaneRoutedOperation>(_ operationType: Operation.Type) -> BackendConfiguration {
        self[operationType.lane]
    }

}

/// Builds one `BackendConfiguration` per lane — each with its own `HTTPClient` and `OperationQueue` —
/// while collaborators that must stay shared across lanes remain shared, so adding a lane costs one
/// entry in `dedicatedLanes`.
struct BackendLanesFactory {

    private let systemInfo: SystemInfo
    private let eTagManager: ETagManager
    private let tokenManager: TokenManager
    private let diagnosticsTracker: DiagnosticsTrackerType?
    private let networkTimeout: NetworkTimeout
    private let apiSourceFailover: APISourceFailoverType?
    private let timeoutManager: HTTPRequestTimeoutManagerType
    private let operationDispatcher: OperationDispatcher
    private let offlineCustomerInfoCreator: OfflineCustomerInfoCreator?
    private let dateProvider: DateProvider

    init(systemInfo: SystemInfo,
         eTagManager: ETagManager,
         tokenManager: TokenManager,
         diagnosticsTracker: DiagnosticsTrackerType?,
         networkTimeout: NetworkTimeout,
         apiSourceFailover: APISourceFailoverType?,
         timeoutManager: HTTPRequestTimeoutManagerType,
         operationDispatcher: OperationDispatcher,
         offlineCustomerInfoCreator: OfflineCustomerInfoCreator?,
         dateProvider: DateProvider) {
        self.systemInfo = systemInfo
        self.eTagManager = eTagManager
        self.tokenManager = tokenManager
        self.diagnosticsTracker = diagnosticsTracker
        self.networkTimeout = networkTimeout
        self.apiSourceFailover = apiSourceFailover
        self.timeoutManager = timeoutManager
        self.operationDispatcher = operationDispatcher
        self.offlineCustomerInfoCreator = offlineCustomerInfoCreator
        self.dateProvider = dateProvider
    }

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
