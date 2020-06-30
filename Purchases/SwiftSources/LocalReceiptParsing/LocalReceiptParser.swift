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

private enum IntroEligibilityStatus: Int {
    case unknown,
         eligible,
         ineligible
}

@objc public class LocalReceiptParser: NSObject {
    
    @objc public func checkTrialOrIntroductoryPriceEligibility(withData data: Data,
                                                               productIdentifiers: [String],
                                                               completion: ([String : NSNumber], Error?) -> Void) {
        completion(["test": NSNumber(value: IntroEligibilityStatus.unknown.rawValue)], nil)
    }
}
