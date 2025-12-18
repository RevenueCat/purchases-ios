//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockSimpleNetworkService.swift
//
//  Created by Jacob Zivan Rakidzich on 8/13/25.

import Foundation
@testable import RevenueCat

class MockSimpleNetworkService: SimpleNetworkServiceType, @unchecked Sendable {

    let lock = NSLock()
    var invocations: [URL] = []
    var stubResponses: [Result<String, Error>] = []

    func bytes(from url: URL) async throws -> AsyncThrowingStream<UInt8, Error> {
        return try lock.withLock {
            let count = invocations.count
            self.invocations.append(url)
            switch stubResponses[count] {
            case .success(let data):
                return AsyncThrowingStream { continuation in
                    data.utf8
                        .forEach { byte in
                            continuation.yield(byte)
                        }
                    continuation.finish()
                }
            case .failure(let error):
                throw error
            }
        }
    }

    func stubResponse(at index: Int, result: Result<String, Error>) {
        lock.withLock {
            stubResponses.insert(result, at: index)
        }
    }

    init() { }
}
