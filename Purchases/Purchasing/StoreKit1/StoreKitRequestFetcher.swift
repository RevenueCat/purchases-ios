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
    private var receiptRefreshCompletionHandlers: [() -> Void]
    private let operationDispatcher: OperationDispatcher

    init(requestFactory: ReceiptRefreshRequestFactory = ReceiptRefreshRequestFactory(),
         operationDispatcher: OperationDispatcher) {
        self.requestFactory = requestFactory
        self.operationDispatcher = operationDispatcher
        receiptRefreshRequest = nil
        receiptRefreshCompletionHandlers = []
    }

    func fetchReceiptData(_ completion: @escaping () -> Void) {
        operationDispatcher.dispatchOnWorkerThread {
            self.receiptRefreshCompletionHandlers.append(completion)

            if self.receiptRefreshRequest == nil {
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

        finishReceiptRequest(request)
        request.cancel()
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        guard request is SKReceiptRefreshRequest else { return }

        Logger.appleError(Strings.storeKit.skrequest_failed(error: error))
        finishReceiptRequest(request)
        request.cancel()
    }

}

private extension StoreKitRequestFetcher {

    func finishReceiptRequest(_ request: SKRequest?) {
        operationDispatcher.dispatchOnWorkerThread {
            self.receiptRefreshRequest = nil
            let completionHandlers = self.receiptRefreshCompletionHandlers
            self.receiptRefreshCompletionHandlers = []

            self.operationDispatcher.dispatchOnWorkerThread {
                for handler in completionHandlers {
                    handler()
                }
            }
        }
    }

}
