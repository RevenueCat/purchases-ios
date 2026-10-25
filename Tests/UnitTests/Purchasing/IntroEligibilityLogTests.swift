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
@testable import RevenueCat
import XCTest

class IntroEligibilityLogTests: TestCase {

    func testStagesShareIdentifierAndMeasureTimeIndependentlyOfWallClock() async throws {
        let clock = TestClock()
        let log = IntroEligibilityLog(clock: clock)
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "product"))

        let products = await log.products(identifiers: ["product", "missing"]) { identifiers in
            expect(identifiers) == ["product", "missing"]
            clock.advance(by: .seconds(2))
            clock.now = .distantPast
            return Set([product])
        }
        let eligible = await log.eligibility(forSubscriptionGroup: "group") { groupID in
            expect(groupID) == "group"
            clock.advance(by: .seconds(3))
            return false
        }
        log.finished([
            "product": .init(eligibilityStatus: .ineligible),
            "missing": .init(eligibilityStatus: .unknown),
            "trial": .init(eligibilityStatus: .eligible),
            "lifetime": .init(eligibilityStatus: .noIntroOfferExists)
        ])

        expect(products.onlyElement) === product
        expect(eligible) == false
        let messages = self.logger.messages.filter { $0.message.contains("Intro eligibility (") }
        expect(messages).to(haveCount(5))
        let prefix = try XCTUnwrap(messages.first?.message.components(separatedBy: ": starting").first)
        expect(messages.allSatisfy { $0.message.hasPrefix(prefix) && $0.level == .debug }) == true
        self.logger.verifyMessageWasLogged("product lookup finished in 2.0s", expectedCount: 1)
        self.logger.verifyMessageWasLogged("missing products: [\"missing\"]", expectedCount: 1)
        self.logger.verifyMessageWasLogged("finished in 3.0s; eligible=false", expectedCount: 1)
        self.logger.verifyMessageWasLogged("check finished in 5.0s", expectedCount: 1)
        self.logger.verifyMessageWasLogged(Strings.eligibility.sk2_intro_eligibility_too_slow,
                                           level: .warn, expectedCount: 1)
        for status in IntroEligibilityStatus.allCases {
            self.logger.verifyMessageWasLogged(status.description, expectedCount: 1)
        }
    }

    func testProductFailureIsLoggedWithDurationAndOriginalErrorIsRethrown() async {
        let clock = TestClock()
        let log = IntroEligibilityLog(clock: clock)
        let expectedError = NSError(domain: "ProductLookupTest", code: 42)

        do {
            let _: Set<StoreProduct> = try await log.products(identifiers: ["product"]) { _ in
                clock.advance(by: .seconds(4))
                throw expectedError
            }
            XCTFail("Expected the product lookup error")
        } catch {
            expect(error as NSError) === expectedError
        }

        self.logger.verifyMessageWasLogged("product lookup failed after 4.0s", level: .debug, expectedCount: 1)
        self.logger.verifyMessageWasLogged("ProductLookupTest (42)", level: .debug, expectedCount: 1)
        self.logger.verifyMessageWasNotLogged("product lookup finished")
    }

    func testProductLookupCancellationIsNotSwallowedOrConverted() async {
        let log = IntroEligibilityLog()

        do {
            let _: Set<StoreProduct> = try await log.products(identifiers: ["product"]) { _ in
                throw CancellationError()
            }
            XCTFail("Expected cancellation")
        } catch {
            expect(error).to(beAnInstanceOf(CancellationError.self))
        }

        self.logger.verifyMessageWasLogged("product lookup failed", level: .debug, expectedCount: 1)
        self.logger.verifyMessageWasNotLogged("product lookup finished")
    }

}
