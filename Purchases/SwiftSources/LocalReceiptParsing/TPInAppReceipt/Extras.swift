//
//  InAppReceiptManager.swift
//  TPInAppReceipt
//
//  Created by Pavel Tikhonenko on 13.02.2020.
//  Copyright © 2020 Pavel Tikhonenko. All rights reserved.
//

#if canImport(StoreKit)

import Foundation
import StoreKit

@available(watchOSApplicationExtension 6.2, *)
fileprivate var refreshSession: RefreshSession?

extension InAppReceipt
{
    /**
    *  Refresh local in-app receipt
    *  - Parameter completion: handler for result
    */
    @available(watchOSApplicationExtension 6.2, *)
    static func refresh(completion: @escaping IAPRefreshRequestResult)
    {
        if refreshSession != nil { return }
        
        refreshSession = RefreshSession()
        refreshSession!.refresh { (error) in
            completion(error)
            InAppReceipt.destroyRefreshSession()
        }
    }

    @available(watchOSApplicationExtension 6.2, *)
    static fileprivate func destroyRefreshSession()
    {
        refreshSession = nil
    }
}

typealias IAPRefreshRequestResult = ((Error?) -> ())

@available(watchOSApplicationExtension 6.2, *)
fileprivate class RefreshSession : NSObject, SKRequestDelegate
{
    private let receiptRefreshRequest = SKReceiptRefreshRequest()
    private var completion: IAPRefreshRequestResult?
    
    
    override init()
    {
        super.init()

        receiptRefreshRequest.delegate = self
    }
    
    func refresh(completion: @escaping IAPRefreshRequestResult)
    {
        self.completion = completion
        
        receiptRefreshRequest.start()
    }
    
    func requestDidFinish(_ request: SKRequest)
    {
        requestDidFinish(with: nil)
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error)
    {
        print("Something went wrong: \(error.localizedDescription)")
        
        requestDidFinish(with: error)
    }
    
    func requestDidFinish(with error: Error?)
    {
        DispatchQueue.main.async { [weak self] in
            self?.completion?(error)
        }
    }
}

#endif
