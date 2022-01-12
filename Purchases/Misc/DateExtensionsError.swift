//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Created by Andrés Boedo on 8/7/20.
//

import Foundation

enum DateExtensionsError: Error {

    case invalidDateComponents(_ dateComponents: DateComponents)

}

extension DateExtensionsError: CustomStringConvertible {

    var description: String {
        switch self {
        case .invalidDateComponents(let dateComponents):
            return "invalid date components: \(dateComponents.description)"
        }
    }

}
