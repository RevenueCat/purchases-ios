//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptParserFetchingTests.swift
//
//  Created by Nacho Soto on 1/10/23.

import Nimble
@testable import ReceiptParser
import XCTest

class ReceiptParserFetchingTests: XCTestCase { // swiftlint:disable:this type_body_length

    private let parser: LocalReceiptFetcher = .init()
    private var mockFileReader: MockFileReader!
    private var mockBundle: MockBundle!

    override func setUp() {
        super.setUp()

        self.mockFileReader = .init()
        self.mockBundle = .init()
    }

    func testParseWithNoReceiptThrowsError() throws {
        self.mockBundle.receiptURLResult = .sandboxReceipt

        do {
            _ = try self.fetchAndParse()
            fail("Expected error")
        } catch PurchasesReceiptParser.Error.failedToLoadLocalReceipt {
            // expected error
        } catch {
            fail("Unexpected error: \(error)")
        }

        expect(self.mockFileReader.invokedContentsOfURL).to(haveCount(1))
        expect(self.mockFileReader.invokedContentsOfURL.first?.value) == 1
    }

    func testParseWithNilURLThrowsError() throws {
        self.mockBundle.receiptURLResult = .nilURL

        do {
            _ = try self.fetchAndParse()
            fail("Expected error")
        } catch {
            expect(error).to(matchError(PurchasesReceiptParser.Error.receiptNotPresent))
        }
    }

    func testParsingEmptyReceiptThrowsError() throws {
        self.mockBundle.receiptURLResult = .sandboxReceipt
        self.mockFileReader.mock(url: try XCTUnwrap(self.mockBundle.appStoreReceiptURL), with: Data())

        do {
            _ = try self.fetchAndParse()
            fail("Expected error")
        } catch PurchasesReceiptParser.Error.failedToLoadLocalReceipt(MockFileReader.Error.emptyMockedData) {
            // expected error
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

    func testParseReceipt() throws { // swiftlint:disable:this function_body_length
        self.mockBundle.receiptURLResult = .appStoreReceipt

        let receiptURL = try XCTUnwrap(self.mockBundle.appStoreReceiptURL)
        let data = try DefaultFileReader().contents(of: receiptURL)
        let decodedData = try XCTUnwrap(
            Data(base64Encoded: XCTUnwrap(String(data: data, encoding: .utf8)))
        )

        self.mockFileReader.mock(url: receiptURL, with: decodedData)

        let receipt = try self.fetchAndParse()
        expect(receipt.environment) == .sandbox
        expect(receipt.bundleId) ==  "com.revenuecat.sampleapp"
        expect(receipt.applicationVersion) == "4"
        expect(receipt.originalApplicationVersion) == "1.0"
        expect(receipt.opaqueValue) == (try XCTUnwrap(Data(base64Encoded: "S5Yfx+yvdaa9O5w6EvDuZA==")))
        expect(receipt.sha1Hash) == (try XCTUnwrap(Data(base64Encoded: "deUV5jHlBbtD8cm+XBgY/95o7zw=")))
        expect(receipt.creationDate) == Date(timeIntervalSince1970: 1595439548.0)
        expect(receipt.expirationDate).to(beNil())
        expect(receipt.inAppPurchases) == [
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692879214",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594755400.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594755700.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054042695,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692901513",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594762977.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594763277.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054042739,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692902182",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594763277.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594763577.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054044460,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692902990",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594763577.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594763877.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054044520,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692905419",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594763877.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594764177.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054044587,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692905971",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594764177.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594764477.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054044637,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692906727",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594764500.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594764800.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054044710,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.annual_39.99.2_week_intro",
                                       transactionId: "1000000696553650",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1595439546.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1595443146.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054044800,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692878476",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594755206.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594755386.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: true,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054042694,
                                       promotionalOfferIdentifier: nil)
        ]
    }

    func testParseSandboxReceipt() throws { // swiftlint:disable:this function_body_length
        self.mockBundle.receiptURLResult = .sandboxReceipt

        let receiptURL = try XCTUnwrap(self.mockBundle.appStoreReceiptURL)
        let data = try DefaultFileReader().contents(of: receiptURL)
        let decodedData = try XCTUnwrap(
            Data(base64Encoded: XCTUnwrap(String(data: data, encoding: .utf8)))
        )

        self.mockFileReader.mock(url: receiptURL, with: decodedData)

        let receipt = try self.fetchAndParse()
        expect(receipt.environment) == .sandbox
        expect(receipt.bundleId) ==  "com.revenuecat.sampleapp"
        expect(receipt.applicationVersion) == "4"
        expect(receipt.originalApplicationVersion) == "1.0"
        expect(receipt.opaqueValue) == (try XCTUnwrap(Data(base64Encoded: "S5Yfx+yvdaa9O5w6EvDuZA==")))
        expect(receipt.sha1Hash) == (try XCTUnwrap(Data(base64Encoded: "deUV5jHlBbtD8cm+XBgY/95o7zw=")))
        expect(receipt.creationDate) == Date(timeIntervalSince1970: 1595439548.0)
        expect(receipt.expirationDate).to(beNil())
        expect(receipt.inAppPurchases) == [
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692879214",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594755400.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594755700.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054042695,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692901513",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594762977.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594763277.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054042739,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692902182",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594763277.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594763577.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054044460,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692902990",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594763577.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594763877.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054044520,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692905419",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594763877.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594764177.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054044587,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692905971",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594764177.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594764477.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054044637,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692906727",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594764500.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594764800.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054044710,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.annual_39.99.2_week_intro",
                                       transactionId: "1000000696553650",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1595439546.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1595443146.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054044800,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "com.revenuecat.monthly_4.99.1_week_intro",
                                       transactionId: "1000000692878476",
                                       originalTransactionId: "1000000692878476",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1594755206.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1594755207.0),
                                       expiresDate: Date(timeIntervalSince1970: 1594755386.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: true,
                                       isInIntroOfferPeriod: false,
                                       webOrderLineItemId: 1000000054042694,
                                       promotionalOfferIdentifier: nil)
        ]
    }

    func testParseSandboxReceipt2() throws { // swiftlint:disable:this function_body_length
        self.mockBundle.receiptURLResult = .sandboxReceipt2

        let receiptURL = try XCTUnwrap(self.mockBundle.appStoreReceiptURL)
        let data = try DefaultFileReader().contents(of: receiptURL)
        let decodedData = try XCTUnwrap(
            Data(base64Encoded: XCTUnwrap(String(data: data, encoding: .utf8)))
        )

        self.mockFileReader.mock(url: receiptURL, with: decodedData)

        let receipt = try self.fetchAndParse()
        expect(receipt.environment) == .sandbox
        expect(receipt.bundleId) ==  "com.mbaasy.ios.demo"
        expect(receipt.applicationVersion) == "1"
        expect(receipt.originalApplicationVersion) == "1.0"
        expect(receipt.opaqueValue) == (try XCTUnwrap(Data(base64Encoded: "xN1AVLC2Gge+tYX2qELgSA==")))
        expect(receipt.sha1Hash) == (try XCTUnwrap(Data(base64Encoded: "LgoRW+rBxXAjpb03NJlVqa2Z200=")))
        expect(receipt.creationDate) == Date(timeIntervalSince1970: 1439452246.0)
        expect(receipt.expirationDate).to(beNil())
        expect(receipt.inAppPurchases) == [
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "consumable",
                                       transactionId: "1000000166865231",
                                       originalTransactionId: "1000000166865231",
                                       productType: .consumable,
                                       purchaseDate: Date(timeIntervalSince1970: 1438979875.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1438979875.0),
                                       expiresDate: nil,
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: nil,
                                       webOrderLineItemId: 0,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "monthly",
                                       transactionId: "1000000166965150",
                                       originalTransactionId: "1000000166965150",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1439189372.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1439189373.0),
                                       expiresDate: Date(timeIntervalSince1970: 1439189672.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: nil,
                                       webOrderLineItemId: 1000000030274153,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "monthly",
                                       transactionId: "1000000166965327",
                                       originalTransactionId: "1000000166965150",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1439189672.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1439189598.0),
                                       expiresDate: Date(timeIntervalSince1970: 1439189972.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: nil,
                                       webOrderLineItemId: 1000000030274154,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "monthly",
                                       transactionId: "1000000166965895",
                                       originalTransactionId: "1000000166965150",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1439189972.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1439189854.0),
                                       expiresDate: Date(timeIntervalSince1970: 1439190272.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: nil,
                                       webOrderLineItemId: 1000000030274165,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "monthly",
                                       transactionId: "1000000166967152",
                                       originalTransactionId: "1000000166965150",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1439190272.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1439190153.0),
                                       expiresDate: Date(timeIntervalSince1970: 1439190572.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: nil,
                                       webOrderLineItemId: 1000000030274192,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "monthly",
                                       transactionId: "1000000166967484",
                                       originalTransactionId: "1000000166965150",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1439190572.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1439190510.0),
                                       expiresDate: Date(timeIntervalSince1970: 1439190872.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: nil,
                                       webOrderLineItemId: 1000000030274219,
                                       promotionalOfferIdentifier: nil),
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "monthly",
                                       transactionId: "1000000166967782",
                                       originalTransactionId: "1000000166965150",
                                       productType: .autoRenewableSubscription,
                                       purchaseDate: Date(timeIntervalSince1970: 1439190872.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1439190754.0),
                                       expiresDate: Date(timeIntervalSince1970: 1439191172.0),
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: nil,
                                       webOrderLineItemId: 1000000030274249,
                                       promotionalOfferIdentifier: nil)
        ]
    }

    func testParseSandboxReceipt3() throws {
        self.mockBundle.receiptURLResult = .sandboxReceipt3

        let receiptURL = try XCTUnwrap(self.mockBundle.appStoreReceiptURL)
        let data = try DefaultFileReader().contents(of: receiptURL)
        let decodedData = try XCTUnwrap(
            Data(base64Encoded: XCTUnwrap(String(data: data, encoding: .utf8)))
        )

        self.mockFileReader.mock(url: receiptURL, with: decodedData)

        let receipt = try self.fetchAndParse()
        expect(receipt.environment) == .sandbox
        expect(receipt.bundleId) ==  "com.belive.app.ios"
        expect(receipt.applicationVersion) == "3"
        expect(receipt.originalApplicationVersion) == "1.0"
        expect(receipt.opaqueValue) == (try XCTUnwrap(Data(base64Encoded: "NOI0mwvWYuTsEnpr/RCvJA==")))
        expect(receipt.sha1Hash) == (try XCTUnwrap(Data(base64Encoded: "JzhO1BR1kxOVGrCEqQLkwvUuZP8=")))
        expect(receipt.creationDate) == Date(timeIntervalSince1970: 1542127591.0)
        expect(receipt.expirationDate).to(beNil())
        expect(receipt.inAppPurchases) == [
            AppleReceipt.InAppPurchase(quantity: 1,
                                       productId: "test2",
                                       transactionId: "1000000472106082",
                                       originalTransactionId: "1000000472106082",
                                       productType: .consumable,
                                       purchaseDate: Date(timeIntervalSince1970: 1542127591.0),
                                       originalPurchaseDate: Date(timeIntervalSince1970: 1542127591.0),
                                       expiresDate: nil,
                                       cancellationDate: nil,
                                       isInTrialPeriod: false,
                                       isInIntroOfferPeriod: nil,
                                       webOrderLineItemId: 0,
                                       promotionalOfferIdentifier: nil)
        ]
    }

    func testParseUnsupportedReceipt1() throws {
        self.mockBundle.receiptURLResult = .unsupportedReceipt1

        let receiptURL = try XCTUnwrap(self.mockBundle.appStoreReceiptURL)
        let data = try DefaultFileReader().contents(of: receiptURL)
        let decodedData = try XCTUnwrap(
            Data(base64Encoded: XCTUnwrap(String(data: data, encoding: .utf8)))
        )

        self.mockFileReader.mock(url: receiptURL, with: decodedData)
        do {
            _ = try self.fetchAndParse()
            fail("Expected error")
        } catch {
            expect(error).to(matchError(
                PurchasesReceiptParser.Error.asn1ParsingError(description: "payload is shorter than length value"))
            )
        }
    }

    func testParseUnsupportedReceipt2() throws {
        self.mockBundle.receiptURLResult = .unsupportedReceipt2

        let receiptURL = try XCTUnwrap(self.mockBundle.appStoreReceiptURL)
        let data = try DefaultFileReader().contents(of: receiptURL)
        let decodedData = try XCTUnwrap(
            Data(base64Encoded: XCTUnwrap(String(data: data, encoding: .utf8)))
        )

        self.mockFileReader.mock(url: receiptURL, with: decodedData)
        do {
            _ = try self.fetchAndParse()
            fail("Expected error")
        } catch {
            expect(error).to(matchError(
                PurchasesReceiptParser.Error.asn1ParsingError(description: "payload is shorter than length value"))
            )
        }
    }
}

// MARK: - Private

private extension ReceiptParserFetchingTests {

    func fetchAndParse() throws -> AppleReceipt {
        return try self.parser.fetchAndParseLocalReceipt(reader: self.mockFileReader,
                                                         bundle: self.mockBundle,
                                                         receiptParser: .default)
    }

}

// MARK: - MockFileReader

private final class MockFileReader: FileReader {

    enum Error: Swift.Error {
        case noMockedData
        case emptyMockedData
    }

    var mockedURLContents: [URL: Data] = [:]

    func mock(url: URL, with data: Data) {
        self.mockedURLContents[url] = data
    }

    var invokedContentsOfURL: [URL: Int] = [:]

    func contents(of url: URL) throws -> Data {
        self.invokedContentsOfURL[url, default: 0] += 1

        guard let mockedData = self.mockedURLContents[url] else { throw Error.noMockedData }

        if mockedData.isEmpty {
            throw Error.emptyMockedData
        } else {
            return mockedData
        }
    }

}

// swiftlint:disable:this file_length
