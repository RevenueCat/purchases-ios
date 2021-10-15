//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BeginRefundRequestHelper.swift
//
//  Created by Madeline Beyl on 10/13/21.

import StoreKit

enum BeginRefundRequestHelperError: Error {

    case couldntGetWindowScene
    case storeKitBeginRefundRequestNotSupported

}

extension BeginRefundRequestHelperError: CustomStringConvertible {

    var description: String {
        switch self {
        case .couldntGetWindowScene:
            return "Failed to get UIWindowScene"
        case .storeKitBeginRefundRequestNotSupported:
            return "tried to call StoreKit.Transaction.beginRefundRequest in a platform that doesn't support it!"
        }
    }

}

class BeginRefundRequestHelper {

    private let systemInfo: SystemInfo

    init(systemInfo: SystemInfo) {
        self.systemInfo = systemInfo
    }

    @available(iOS 15.0, *)
    @available(macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func beginRefundRequest(transactionId: UInt64,
                            completion: @escaping (Result<RefundRequestStatus,
                                                   BeginRefundRequestHelperError>) -> Void) {
        Task {
            self.beginRefundRequest(transactionId: transactionId, completion: completion)
        }
        return
    }

}

@available(iOS 15.0, *)
@available(macCatalyst 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private extension BeginRefundRequestHelper {

    @MainActor
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    func beginRefundRequest(transactionId: UInt64) async throws
        -> Result<RefundRequestStatus, BeginRefundRequestHelperError> {
        // TODO pull out to some kind of UIHelper class?
        guard let application = systemInfo.sharedUIApplication,
              let windowScene = application.currentWindowScene else {
                  return .failure(.couldntGetWindowScene)
        }

        do {
            let status = try await StoreKit.Transaction.beginRefundRequest(for: transactionId, in: windowScene)

            return .success(RefundRequestStatus.refundRequestStatus(fromSKRefundRequestStatus: status))
        } catch {
            // is this not supported or just failed? should i pass the error?
            return .failure(.storeKitBeginRefundRequestNotSupported)
        }

    }
}

/// Status codes for refund requests
@objc(RCRefundRequestStatus) public enum RefundRequestStatus: Int {
    /// User canceled submission of the refund request
    case userCancelled = 0,
        /// Apple has received the refund request
         success
}

@available(iOS 15.0, *)
@available(macCatalyst 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
private extension RefundRequestStatus {
    static func refundRequestStatus(fromSKRefundRequestStatus status: StoreKit.Transaction.RefundRequestStatus)
        -> RefundRequestStatus {
        switch status {
        case .userCancelled:
            return .userCancelled
        case .success:
            return .success
        @unknown default:
            // todo figure out how to handle this
            fatalError()
        }
    }
}
