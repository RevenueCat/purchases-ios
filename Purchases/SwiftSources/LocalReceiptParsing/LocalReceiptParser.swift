//
//  LocalReceiptParser.swift
//  Purchases
//
//  Created by Andrés Boedo on 6/29/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
@objc public enum LocalReceiptParserErrorCode: Int {
    case ReceiptNotFound,
         UnknownError
}

internal enum IntroEligibilityStatus: Int {
    case unknown,
         ineligible,
         eligible
}

@objc public class LocalReceiptParser: NSObject {
    
    @objc public func checkTrialOrIntroductoryPriceEligibility(withData data: Data,
                                                               productIdentifiers: [String],
                                                               completion: ([String : Int], Error?) -> Void) {
        completion([:], NSError(domain: "This method hasn't been implemented yet",
                                code: LocalReceiptParserErrorCode.UnknownError.rawValue,
                                userInfo: nil))
    }
}
