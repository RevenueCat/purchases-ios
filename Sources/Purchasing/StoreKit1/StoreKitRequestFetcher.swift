//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitRequestFetcher.swift
//
//  Created by Andrés Boedo on 6/29/21.
//

import Foundation
import StoreKit

class ReceiptRefreshRequestFactory {

    func receiptRefreshRequest() -> SKReceiptRefreshRequest {
        return SKReceiptRefreshRequest()
    }

}

class StoreKitRequestFetcher: NSObject {

    private let requestFactory: ReceiptRefreshRequestFactory
    private var receiptRefreshRequest: SKRequest?
    private var receiptRefreshCompletionHandlers: [@MainActor @Sendable () -> Void]
    private let operationDispatcher: OperationDispatcher

    init(requestFactory: ReceiptRefreshRequestFactory = ReceiptRefreshRequestFactory(),
         operationDispatcher: OperationDispatcher) {
        self.requestFactory = requestFactory
        self.operationDispatcher = operationDispatcher
        self.receiptRefreshRequest = nil
        self.receiptRefreshCompletionHandlers = []
    }

    func fetchReceiptData(_ completion: @MainActor @Sendable @escaping () -> Void) {
        self.operationDispatcher.dispatchOnWorkerThread {
            self.receiptRefreshCompletionHandlers.append(completion)

            if self.receiptRefreshRequest == nil {
                Logger.debug(Strings.storeKit.sk_receipt_request_started)

                self.receiptRefreshRequest = self.requestFactory.receiptRefreshRequest()
                self.receiptRefreshRequest?.delegate = self
                self.receiptRefreshRequest?.start()
            }
        }
    }

}

extension StoreKitRequestFetcher: SKRequestDelegate {

    func requestDidFinish(_ request: SKRequest) {
        guard request is SKReceiptRefreshRequest else { return }

        Logger.debug(Strings.storeKit.sk_receipt_request_finished)
        self.finishReceiptRequest(request)
        request.cancel()
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        guard request is SKReceiptRefreshRequest else { return }

        Logger.appleError(Strings.storeKit.skrequest_failed(error as NSError))
        self.finishReceiptRequest(request)
        request.cancel()
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension ReceiptRefreshRequestFactory: @unchecked Sendable {}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
// - It has mutable state, but it's made thread-safe through `operationDispatcher`.
extension StoreKitRequestFetcher: @unchecked Sendable {}

// MARK: -

private extension StoreKitRequestFetcher {

    func finishReceiptRequest(_ request: SKRequest?) {
        self.operationDispatcher.dispatchOnWorkerThread {
            self.receiptRefreshRequest = nil
            let completionHandlers = self.receiptRefreshCompletionHandlers
            self.receiptRefreshCompletionHandlers = []

            for handler in completionHandlers {
                self.operationDispatcher.dispatchOnMainActor {
                    handler()
                }
            }
        }
    }

}
