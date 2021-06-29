//
//  StoreKitRequestFetcher.swift
//  PurchasesCoreSwift
//
//  Created by Andrés Boedo on 6/29/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
import StoreKit

@objc(RCReceiptRefreshRequestFactory) public class ReceiptRefreshRequestFactory: NSObject {

    @objc public func receiptRefreshRequest() -> SKReceiptRefreshRequest {
        return SKReceiptRefreshRequest()
    }
}

@objc(RCStoreKitRequestFetcher) public class StoreKitRequestFetcher: NSObject {
    private let requestFactory: ReceiptRefreshRequestFactory
    private var receiptRefreshRequest: SKRequest?
    private var receiptRefreshCompletionHandlers: [() -> Void]
    private let queue = DispatchQueue(label: "StoreKitRequestFetcher")

    @objc public init(requestFactory: ReceiptRefreshRequestFactory = ReceiptRefreshRequestFactory()) {
        self.requestFactory = requestFactory
        receiptRefreshRequest = nil
        receiptRefreshCompletionHandlers = []
    }

    @objc public func fetchReceiptData(_ completion: @escaping () -> Void) {
        queue.async {
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
        queue.async {
            self.receiptRefreshRequest = nil
            let handlers = self.receiptRefreshCompletionHandlers
            self.receiptRefreshCompletionHandlers = []
            for handler in handlers {
                handler()
            }
        }
    }
}
