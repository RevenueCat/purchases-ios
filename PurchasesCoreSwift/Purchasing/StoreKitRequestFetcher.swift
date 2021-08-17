//
//  StoreKitRequestFetcher.swift
//  PurchasesCoreSwift
//
//  Created by Andrés Boedo on 6/29/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
import StoreKit

// todo: make internal
@objc(RCReceiptRefreshRequestFactory) public class ReceiptRefreshRequestFactory: NSObject {

    func receiptRefreshRequest() -> SKReceiptRefreshRequest {
        return SKReceiptRefreshRequest()
    }
}

// todo: make internal
@objc(RCStoreKitRequestFetcher) public class StoreKitRequestFetcher: NSObject {
    private let requestFactory: ReceiptRefreshRequestFactory
    private var receiptRefreshRequest: SKRequest?
    private var receiptRefreshCompletionHandlers: [() -> Void]
    private let operationDispatcher: OperationDispatcher

    @objc public init(requestFactory: ReceiptRefreshRequestFactory = ReceiptRefreshRequestFactory(),
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

    public func requestDidFinish(_ request: SKRequest) {
        guard request is SKReceiptRefreshRequest else { return }

        finishReceiptRequest(request)
        request.cancel()
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        guard request is SKReceiptRefreshRequest else { return }

        Logger.appleError(String(format: Strings.offering.sk_request_failed, error.localizedDescription))
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
