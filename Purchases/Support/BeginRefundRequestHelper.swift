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

class BeginRefundRequestHelper {

    private let systemInfo: SystemInfo

#if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    lazy var sk2Helper = SK2BeginRefundRequestHelper()
#endif

    init(systemInfo: SystemInfo) {
        self.systemInfo = systemInfo
    }

    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func beginRefundRequest(productID: String,
                            completion: @escaping (Result<RefundRequestStatus,
                                                   Error>) -> Void) {
#if os(iOS) || targetEnvironment(macCatalyst)
        Task {
            let result = await self.beginRefundRequest(productID: productID)
            completion(result)
        }

        return
#else
        fatalError(Strings.purchase.begin_refund_request_unsupported.description)
#endif
    }

}

#if os(iOS) || targetEnvironment(macCatalyst)
@available(iOS 15.0, macCatalyst 15.0, *)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(macOS, unavailable)
private extension BeginRefundRequestHelper {

    @MainActor
    @available(iOS 15.0, macCatalyst 15.0, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    @available(macOS, unavailable)
    func beginRefundRequest(productID: String) async -> Result<RefundRequestStatus, Error> {
        guard let windowScene = systemInfo.sharedUIApplication?.currentWindowScene else {
            return .failure(ErrorUtils.storeProblemError(withMessage: "Failed to get UIWindowScene"))
        }

        let transactionVerificationResult = await sk2Helper.verifyTransaction(productID: productID)

        switch transactionVerificationResult {
        case .failure(let verificationError):
            return .failure(verificationError)
        case .success(let transactionID):
            return await sk2Helper.initiateRefundRequest(transactionID: transactionID,
                                                         windowScene: windowScene)
        }
    }

}
#endif

/// Status codes for refund requests
@objc(RCRefundRequestStatus) public enum RefundRequestStatus: Int {
    /// User canceled submission of the refund request
    @objc(RCRefundRequestUserCancelled) case userCancelled = 0
     /// Apple has received the refund request
    @objc(RCRefundRequestSuccess) case success
     /// There was an error with the request. See message for more details
    @objc(RCRefundRequestError) case error
}
