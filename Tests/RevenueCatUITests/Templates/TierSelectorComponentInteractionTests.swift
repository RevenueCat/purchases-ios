//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Nimble
import RevenueCat
@testable import RevenueCatUI

class TierSelectorComponentInteractionTests: TestCase {

    func testUsesNonBlankTierName() {
        expect(
            tierSelectorComponentInteractionValue(tierName: "Premium", tierId: "tier_abc")
        ) == "Premium"
    }

    func testFallsBackToTierIdWhenTierNameIsNil() {
        expect(
            tierSelectorComponentInteractionValue(tierName: nil, tierId: "tier_abc")
        ) == "tier_abc"
    }

    func testFallsBackToTierIdWhenTierNameIsBlank() {
        expect(
            tierSelectorComponentInteractionValue(tierName: "  ", tierId: "id_only")
        ) == "id_only"
    }
}
