//
//  HTTPRequestTimeoutManager.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 06/11/2025.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation

class HTTPRequestTimeoutManager {
    
    enum RequestResult {
        
        /**
         * Request succeeded on the main backend
         */
        case successOnMainBackend
        
        /**
         * Request timed out on the main backend and supports fallback URLs
         */
        case timeoutOnMainBackendSupportingFallback
        
        /**
         * Any other result (non-main backend, non-timeout errors, etc.)
         */
        case other
    }
    
    enum Timeout: TimeInterval {
        case `default` = 30
        case defaultForMainBackendRequestSupportingFallback = 5
        case reduced = 2
    }
    
    private static let timeoutResetInterval: TimeInterval = 10
    
    private var lastTimeoutRequestTime: Date?
    
    private let dateProvider: DateProvider
    
    init(dateProvider: DateProvider) {
        self.dateProvider = dateProvider
    }
    
    func timeout(for path: HTTPRequestPath, isFallback: Bool) -> TimeInterval {
        if shouldResetTimeout {
            resetTimeout()
        }
        
        let timeout: Timeout
        if isFallback || path.fallbackUrls.isEmpty {
            timeout = .default
        }
        else if lastTimeoutRequestTime != nil {
            timeout = .reduced
        }
        else {
            timeout = .defaultForMainBackendRequestSupportingFallback
        }
        
        return timeout.rawValue
    }
    
    func recordRequestResult(_ result: RequestResult) {
        switch result {
        case .successOnMainBackend:
            resetTimeout()
        case .timeoutOnMainBackendSupportingFallback:
            lastTimeoutRequestTime = dateProvider.now()
        case .other:
            break
        }
    }
    
    private func resetTimeout() {
        lastTimeoutRequestTime = nil
    }
    
    private var shouldResetTimeout: Bool {
        guard let lastTimeoutRequestTime else { return false }
        
        let timeElapsed = dateProvider.now().timeIntervalSince1970 - lastTimeoutRequestTime.timeIntervalSince1970
        return timeElapsed >= Self.timeoutResetInterval
    }
}
