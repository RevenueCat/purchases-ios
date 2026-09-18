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

final class BackendLanes {

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

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension BackendLanes: @unchecked Sendable {}

struct BackendLanesFactory {

    // One `apiSourceFailover` for every lane's HTTPClient, so they walk one source list and one
    // health-check cache; handle tokens keep concurrent unhealthy reports from double-advancing it.
    //
    // `timeoutManager` is shared by every lane's HTTPClient (and, outside of `Backend`, by the blob
    // downloader) so a timeout one of them sees on a host fast-fails the others' next request to that
    // same host, and a success on any of them clears it for all.

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
