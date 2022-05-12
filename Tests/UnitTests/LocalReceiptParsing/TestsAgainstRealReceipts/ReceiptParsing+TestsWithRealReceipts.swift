//
//  ReceiptParsing+TestsWithRealReceipts.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 8/6/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class ReceiptParsingRealReceiptTests: TestCase {

    let receipt1Name = "base64encodedreceiptsample1"

    func testBasicReceiptAttributesForSample1() throws {
        let receiptData = sampleReceiptData(receiptName: receipt1Name)
        let receipt = try ReceiptParser().parse(from: receiptData)

        expect(receipt.applicationVersion) == "4"
        expect(receipt.bundleId) == "com.revenuecat.sampleapp"
        expect(receipt.originalApplicationVersion) == "1.0"
        expect(receipt.creationDate) == Date(timeIntervalSince1970: 1595439548)
        expect(receipt.expirationDate).to(beNil())
    }

    func testInAppPurchasesAttributesForSample1() throws {
        let receiptData = sampleReceiptData(receiptName: receipt1Name)
        let receipt = try ReceiptParser().parse(from: receiptData)
        let inAppPurchases = receipt.inAppPurchases

        expect(inAppPurchases.count) == 9

        let inAppPurchase0 = inAppPurchases[0]
        expect(inAppPurchase0.quantity) == 1
        expect(inAppPurchase0.productId) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(inAppPurchase0.transactionId) == "1000000692879214"
        expect(inAppPurchase0.originalTransactionId) == "1000000692878476"
        expect(inAppPurchase0.productType) == .autoRenewableSubscription
        expect(inAppPurchase0.purchaseDate) == Date(timeIntervalSince1970: 1594755400)
        expect(inAppPurchase0.originalPurchaseDate) == Date(timeIntervalSince1970: 1594755207)
        expect(inAppPurchase0.expiresDate) == Date(timeIntervalSince1970: 1594755700)
        expect(inAppPurchase0.cancellationDate).to(beNil())
        expect(inAppPurchase0.isInTrialPeriod) == false
        expect(inAppPurchase0.isInIntroOfferPeriod) == false
        expect(inAppPurchase0.webOrderLineItemId) == Int64(1000000054042695)
        expect(inAppPurchase0.promotionalOfferIdentifier).to(beNil())

        let inAppPurchase1 = inAppPurchases[1]
        expect(inAppPurchase1.quantity) == 1
        expect(inAppPurchase1.productId) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(inAppPurchase1.transactionId) == "1000000692901513"
        expect(inAppPurchase1.originalTransactionId) == "1000000692878476"
        expect(inAppPurchase1.productType) == .autoRenewableSubscription
        expect(inAppPurchase1.purchaseDate) == Date(timeIntervalSince1970: 1594762977)
        expect(inAppPurchase1.originalPurchaseDate) == Date(timeIntervalSince1970: 1594755207)
        expect(inAppPurchase1.expiresDate) == Date(timeIntervalSince1970: 1594763277)
        expect(inAppPurchase1.cancellationDate).to(beNil())
        expect(inAppPurchase1.isInTrialPeriod) == false
        expect(inAppPurchase1.isInIntroOfferPeriod) == false
        expect(inAppPurchase1.webOrderLineItemId) == Int64(1000000054042739)
        expect(inAppPurchase1.promotionalOfferIdentifier).to(beNil())

        let inAppPurchase2 = inAppPurchases[2]
        expect(inAppPurchase2.quantity) == 1
        expect(inAppPurchase2.productId) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(inAppPurchase2.transactionId) == "1000000692902182"
        expect(inAppPurchase2.originalTransactionId) == "1000000692878476"
        expect(inAppPurchase2.productType) == .autoRenewableSubscription
        expect(inAppPurchase2.purchaseDate) == Date(timeIntervalSince1970: 1594763277)
        expect(inAppPurchase2.originalPurchaseDate) == Date(timeIntervalSince1970: 1594755207)
        expect(inAppPurchase2.expiresDate) == Date(timeIntervalSince1970: 1594763577)
        expect(inAppPurchase2.cancellationDate).to(beNil())
        expect(inAppPurchase2.isInTrialPeriod) == false
        expect(inAppPurchase2.isInIntroOfferPeriod) == false
        expect(inAppPurchase2.webOrderLineItemId) == Int64(1000000054044460)
        expect(inAppPurchase2.promotionalOfferIdentifier).to(beNil())

        let inAppPurchase3 = inAppPurchases[3]
        expect(inAppPurchase3.quantity) == 1
        expect(inAppPurchase3.productId) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(inAppPurchase3.transactionId) == "1000000692902990"
        expect(inAppPurchase3.originalTransactionId) == "1000000692878476"
        expect(inAppPurchase3.productType) == .autoRenewableSubscription
        expect(inAppPurchase3.purchaseDate) == Date(timeIntervalSince1970: 1594763577)
        expect(inAppPurchase3.originalPurchaseDate) == Date(timeIntervalSince1970: 1594755207)
        expect(inAppPurchase3.expiresDate) == Date(timeIntervalSince1970: 1594763877)
        expect(inAppPurchase3.cancellationDate).to(beNil())
        expect(inAppPurchase3.isInTrialPeriod) == false
        expect(inAppPurchase3.isInIntroOfferPeriod) == false
        expect(inAppPurchase3.webOrderLineItemId) == Int64(1000000054044520)
        expect(inAppPurchase3.promotionalOfferIdentifier).to(beNil())

        let inAppPurchase4 = inAppPurchases[4]
        expect(inAppPurchase4.quantity) == 1
        expect(inAppPurchase4.productId) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(inAppPurchase4.transactionId) == "1000000692905419"
        expect(inAppPurchase4.originalTransactionId) == "1000000692878476"
        expect(inAppPurchase4.productType) == .autoRenewableSubscription
        expect(inAppPurchase4.purchaseDate) == Date(timeIntervalSince1970: 1594763877)
        expect(inAppPurchase4.originalPurchaseDate) == Date(timeIntervalSince1970: 1594755207)
        expect(inAppPurchase4.expiresDate) == Date(timeIntervalSince1970: 1594764177)
        expect(inAppPurchase4.cancellationDate).to(beNil())
        expect(inAppPurchase4.isInTrialPeriod) == false
        expect(inAppPurchase4.isInIntroOfferPeriod) == false
        expect(inAppPurchase4.webOrderLineItemId) == Int64(1000000054044587)
        expect(inAppPurchase4.promotionalOfferIdentifier).to(beNil())

        let inAppPurchase5 = inAppPurchases[5]
        expect(inAppPurchase5.quantity) == 1
        expect(inAppPurchase5.productId) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(inAppPurchase5.transactionId) == "1000000692905971"
        expect(inAppPurchase5.originalTransactionId) == "1000000692878476"
        expect(inAppPurchase5.productType) == .autoRenewableSubscription
        expect(inAppPurchase5.purchaseDate) == Date(timeIntervalSince1970: 1594764177)
        expect(inAppPurchase5.originalPurchaseDate) == Date(timeIntervalSince1970: 1594755207)
        expect(inAppPurchase5.expiresDate) == Date(timeIntervalSince1970: 1594764477)
        expect(inAppPurchase5.cancellationDate).to(beNil())
        expect(inAppPurchase5.isInTrialPeriod) == false
        expect(inAppPurchase5.isInIntroOfferPeriod) == false
        expect(inAppPurchase5.webOrderLineItemId) == Int64(1000000054044637)
        expect(inAppPurchase5.promotionalOfferIdentifier).to(beNil())

        let inAppPurchase6 = inAppPurchases[6]
        expect(inAppPurchase6.quantity) == 1
        expect(inAppPurchase6.productId) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(inAppPurchase6.transactionId) == "1000000692906727"
        expect(inAppPurchase6.originalTransactionId) == "1000000692878476"
        expect(inAppPurchase6.productType) == .autoRenewableSubscription
        expect(inAppPurchase6.purchaseDate) == Date(timeIntervalSince1970: 1594764500)
        expect(inAppPurchase6.originalPurchaseDate) == Date(timeIntervalSince1970: 1594755207)
        expect(inAppPurchase6.expiresDate) == Date(timeIntervalSince1970: 1594764800)
        expect(inAppPurchase6.cancellationDate).to(beNil())
        expect(inAppPurchase6.isInTrialPeriod) == false
        expect(inAppPurchase6.isInIntroOfferPeriod) == false
        expect(inAppPurchase6.webOrderLineItemId) == Int64(1000000054044710)
        expect(inAppPurchase6.promotionalOfferIdentifier).to(beNil())

        let inAppPurchase7 = inAppPurchases[7]
        expect(inAppPurchase7.quantity) == 1
        expect(inAppPurchase7.productId) == "com.revenuecat.annual_39.99.2_week_intro"
        expect(inAppPurchase7.transactionId) == "1000000696553650"
        expect(inAppPurchase7.originalTransactionId) == "1000000692878476"
        expect(inAppPurchase7.productType) == .autoRenewableSubscription
        expect(inAppPurchase7.purchaseDate) == Date(timeIntervalSince1970: 1595439546)
        expect(inAppPurchase7.originalPurchaseDate) == Date(timeIntervalSince1970: 1594755207)
        expect(inAppPurchase7.expiresDate) == Date(timeIntervalSince1970: 1595443146)
        expect(inAppPurchase7.cancellationDate).to(beNil())
        expect(inAppPurchase7.isInTrialPeriod) == false
        expect(inAppPurchase7.isInIntroOfferPeriod) == false
        expect(inAppPurchase7.webOrderLineItemId) == Int64(1000000054044800)
        expect(inAppPurchase7.promotionalOfferIdentifier).to(beNil())

        let inAppPurchase8 = inAppPurchases[8]
        expect(inAppPurchase8.quantity) == 1
        expect(inAppPurchase8.productId) == "com.revenuecat.monthly_4.99.1_week_intro"
        expect(inAppPurchase8.transactionId) == "1000000692878476"
        expect(inAppPurchase8.originalTransactionId) == "1000000692878476"
        expect(inAppPurchase8.productType) == .autoRenewableSubscription
        expect(inAppPurchase8.purchaseDate) == Date(timeIntervalSince1970: 1594755206)
        expect(inAppPurchase8.originalPurchaseDate) == Date(timeIntervalSince1970: 1594755207)
        expect(inAppPurchase8.expiresDate) == Date(timeIntervalSince1970: 1594755386)
        expect(inAppPurchase8.cancellationDate).to(beNil())
        expect(inAppPurchase8.isInTrialPeriod) == true
        expect(inAppPurchase8.isInIntroOfferPeriod) == false
        expect(inAppPurchase8.webOrderLineItemId) == Int64(1000000054042694)
        expect(inAppPurchase8.promotionalOfferIdentifier).to(beNil())
    }

}

private extension ReceiptParsingRealReceiptTests {

    func sampleReceiptData(receiptName: String) -> Data {
        NSDataExtensionsTests.sampleReceiptData(receiptName: receiptName)
    }

    func readFile(named filename: String) -> String {
        NSDataExtensionsTests.readFile(named: filename)
    }

}
