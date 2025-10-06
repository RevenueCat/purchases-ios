//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductPaidPriceTests.swift
//
//  Created by Facundo Menzella on 15/1/25.

import Foundation
import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

@available(iOS 11.2, macOS 10.13.2, watchOS 6.2, tvOS 11.2, *)
final class ProductPaidPriceTests: TestCase {

    // MARK: - Basic Initialization Tests

    func testBasicInitialization() {
        let price = ProductPaidPrice(currency: "USD", amount: 4.99, formatted: "$4.99")

        expect(price.currency) == "USD"
        expect(price.amount) == 4.99
        expect(price.formatted) == "$4.99"
    }

    func testBackwardCompatibleInitialization() {
        let price = ProductPaidPrice(currency: "USD", amount: 4.99)

        expect(price.currency) == "USD"
        expect(price.amount) == 4.99
        expect(price.formatted).to(contain("$"))
        expect(price.formatted).to(contain("4.99"))
    }

    // MARK: - Convenience Initializer Tests

    func testConvenienceInitializerFormatsUSDCorrectly() {
        let usLocale = Locale(identifier: "en_US")
        let price = ProductPaidPrice(currency: "USD", amount: 4.99, locale: usLocale)

        expect(price.currency) == "USD"
        expect(price.amount) == 4.99
        expect(price.formatted) == "$4.99"
    }

    func testConvenienceInitializerFormatsEURCorrectly() {
        let frenchLocale = Locale(identifier: "fr_FR")
        let price = ProductPaidPrice(currency: "EUR", amount: 7.99, locale: frenchLocale)

        expect(price.currency) == "EUR"
        expect(price.amount) == 7.99
        expect(price.formatted).to(contain("7,99"))
        expect(price.formatted).to(contain("€"))
    }

    // MARK: - Static formatPrice Method Tests

    func testFormatPriceWithUSD() {
        let usLocale = Locale(identifier: "en_US")
        let formatted = ProductPaidPrice.formatPrice(currency: "USD", amount: 9.99, locale: usLocale)

        expect(formatted) == "$9.99"
    }

    func testFormatPriceWithEUR() {
        let germanLocale = Locale(identifier: "de_DE")
        let formatted = ProductPaidPrice.formatPrice(currency: "EUR", amount: 12.99, locale: germanLocale)

        expect(formatted).to(contain("12,99"))
        expect(formatted).to(contain("€"))
    }

    func testFormatPriceWithJPY() {
        let japanLocale = Locale(identifier: "ja_JP")
        let formatted = ProductPaidPrice.formatPrice(currency: "JPY", amount: 1500, locale: japanLocale)

        expect(formatted).to(contain("1,500"))
        expect(formatted).to(contain("¥"))
    }

    // MARK: - Cross-Platform Consistency Tests

    func testPriceFormattingConsistencyAcrossLocales() {
        let testCases: [(currency: String, amount: Double, locale: String, expectedContains: [String])] = [
            ("USD", 4.99, "en_US", ["$", "4.99"]),
            ("EUR", 7.99, "fr_FR", ["€", "7,99"]),
            ("GBP", 3.49, "en_GB", ["£", "3.49"]),
            ("JPY", 999, "ja_JP", ["¥", "999"])
        ]

        for testCase in testCases {
            let locale = Locale(identifier: testCase.locale)
            let price = ProductPaidPrice(currency: testCase.currency, amount: testCase.amount, locale: locale)

            for expectedSubstring in testCase.expectedContains {
                expect(price.formatted)
                    .to(contain(expectedSubstring), description: """
                        Price formatting for \(testCase.currency)
                        in \(testCase.locale) should contain '\(expectedSubstring)'
                        """)
            }
        }
    }

    // MARK: - StoreProduct Consistency Tests

    func testConsistencyWithSK1StoreProductPricing() {
        // Test that our formatting matches SK1 StoreProduct formatting
        let usLocale = Locale(identifier: "en_US")

        // Create a mock SK1Product with known price and locale
        let mockSK1Product = MockSK1Product(mockProductIdentifier: "mockProductIdentifier")
        mockSK1Product.mockPrice = 4.99
        mockSK1Product.mockPriceLocale = usLocale
        mockSK1Product.mockProductIdentifier = "test_product"

        let sk1StoreProduct = SK1StoreProduct(sk1Product: mockSK1Product)
        let productPaidPrice = ProductPaidPrice(currency: "USD", amount: 4.99, locale: usLocale)

        // Both should format the same price identically
        expect(productPaidPrice.formatted) == sk1StoreProduct.localizedPriceString
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testConsistencyWithStoreProductInterfacePricing() {
        // Test that our formatting matches SK2 StoreProduct formatting
        let usLocale = Locale(identifier: "en_US")

        // Create a TestStoreProduct (SK2 mock) with known price and locale
        let testProduct = TestStoreProduct(
            localizedTitle: "Test Product",
            price: 4.99,
            localizedPriceString: "$4.99",
            productIdentifier: "test.product",
            productType: .autoRenewableSubscription,
            localizedDescription: "Test subscription",
            locale: usLocale
        )

        let sk2StoreProduct = testProduct.toStoreProduct()
        let productPaidPrice = ProductPaidPrice(currency: "USD", amount: 4.99, locale: usLocale)

        // Both should format the same price identically
        expect(productPaidPrice.formatted) == sk2StoreProduct.localizedPriceString
    }

    // MARK: - Edge Cases Tests

    func testZeroPriceFormatting() {
        let usLocale = Locale(identifier: "en_US")
        let price = ProductPaidPrice(currency: "USD", amount: 0.0, locale: usLocale)

        expect(price.formatted) == "$0.00"
    }

    func testLargePriceFormatting() {
        let usLocale = Locale(identifier: "en_US")
        let price = ProductPaidPrice(currency: "USD", amount: 9999.99, locale: usLocale)

        expect(price.formatted) == "$9,999.99"
    }

    func testSmallDecimalPriceFormatting() {
        let usLocale = Locale(identifier: "en_US")
        let price = ProductPaidPrice(currency: "USD", amount: 0.99, locale: usLocale)

        expect(price.formatted) == "$0.99"
    }

    func testInvalidCurrencyCodeFallback() {
        let usLocale = Locale(identifier: "en_US")
        let formatted = ProductPaidPrice.formatPrice(currency: "INVALID", amount: 4.99, locale: usLocale)

        // Should fallback to showing the raw amount when currency is invalid
        expect(formatted).to(contain("4.99"))
    }

    func testLocaleCurrencyMismatch() {
        // Test Spanish locale formatting USD currency (common real-world scenario)
        let spanishLocale = Locale(identifier: "es_ES")
        let price = ProductPaidPrice(currency: "USD", amount: 4.99, locale: spanishLocale)

        expect(price.currency) == "USD"
        expect(price.amount) == 4.99
        // Spanish locale should still show USD correctly, possibly with different formatting
        expect(price.formatted).to(contain("4,99"))  // Spanish uses comma for decimals
        expect(price.formatted).to(contain("US$"))   // Spanish locale shows US$ for USD
    }

    // MARK: - Thread Safety Tests

    func testConcurrentFormatPriceCalls() async throws {
        let currency = "USD"
        let amount = 4.99
        let locale = Locale(identifier: "en_US")
        let expectedFormat = "$4.99"
        
        var tasks: [Task<String, Never>] = []
        
        // Create multiple concurrent formatting tasks
        for _ in 0..<50 {
            tasks.append(
                Task {
                    return ProductPaidPrice.formatPrice(currency: currency, amount: amount, locale: locale)
                }
            )
        }
        
        // Collect all results
        var results: [String] = []
        for task in tasks {
            results.append(await task.value)
        }
        
        // All results should be identical
        for result in results {
            expect(result) == expectedFormat
        }
    }

    func testConcurrentInitializationWithSameParameters() async throws {
        let currency = "EUR"
        let amount = 7.99
        let locale = Locale(identifier: "fr_FR")
        
        async let price1 = Task { ProductPaidPrice(currency: currency, amount: amount, locale: locale) }
        async let price2 = Task { ProductPaidPrice(currency: currency, amount: amount, locale: locale) }
        async let price3 = Task { ProductPaidPrice(currency: currency, amount: amount, locale: locale) }
        async let price4 = Task { ProductPaidPrice(currency: currency, amount: amount, locale: locale) }
        async let price5 = Task { ProductPaidPrice(currency: currency, amount: amount, locale: locale) }
        
        let (result1, result2, result3, result4, result5) = await (
            price1.value, price2.value, price3.value, price4.value, price5.value
        )
        
        // All should have identical formatted values
        let prices = [result1, result2, result3, result4, result5]
        let firstFormatted = prices.first!.formatted
        
        for price in prices {
            expect(price.formatted) == firstFormatted
            expect(price.currency) == currency
            expect(price.amount) == amount
        }
    }

    func testHighVolumeConcurrentAccess() async throws {
        let testCases = [
            ("USD", 4.99, "en_US"),
            ("EUR", 7.99, "fr_FR"),
            ("JPY", 1500.0, "ja_JP"),
            ("GBP", 3.49, "en_GB")
        ]
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                for testCase in testCases {
                    group.addTask {
                        let locale = Locale(identifier: testCase.2)
                        let price = ProductPaidPrice(currency: testCase.0, amount: testCase.1, locale: locale)
                        
                        _ = price.currency
                        _ = price.amount  
                        _ = price.formatted
                    }
                }
            }
            
            await group.waitForAll()
        }
    }

    func testFormatterCacheCoherencyUnderConcurrentAccess() async throws {
        let currencies = ["USD", "EUR", "GBP", "JPY"]
        let locales = ["en_US", "fr_FR", "en_GB", "ja_JP"]
        let amounts = [1.99, 9.99, 49.99, 199.99]
        
        // Test that cache remains coherent under concurrent access
        await withTaskGroup(of: (String, String, Double, String).self) { group in
            for currency in currencies {
                for localeId in locales {
                    for amount in amounts {
                        group.addTask {
                            let locale = Locale(identifier: localeId)
                            let formatted = ProductPaidPrice.formatPrice(
                                currency: currency, 
                                amount: amount, 
                                locale: locale
                            )
                            return (currency, localeId, amount, formatted)
                        }
                    }
                }
            }
            
            var results: [String: String] = [:]
            
            for await (currency, localeId, amount, formatted) in group {
                let key = "\(currency)-\(localeId)-\(amount)"
                
                if let existingFormatted = results[key] {
                    // Same parameters should always produce same result
                    expect(formatted) == existingFormatted
                } else {
                    results[key] = formatted
                }
            }
        }
    }
}
