//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptFetcherTests.swift
//
//  Created by Andrés Boedo on 8/3/21.

import Foundation
import XCTest

import Nimble
@testable import RevenueCat

class ReceiptFetcherTests: TestCase {

    private var receiptFetcher: ReceiptFetcher!
    private var mockRequestFetcher: MockRequestFetcher!
    private var mockBundle: MockBundle!
    private var mockSystemInfo: MockSystemInfo!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockBundle = MockBundle()
        self.mockRequestFetcher = MockRequestFetcher()
        self.mockSystemInfo = try MockSystemInfo(platformInfo: nil,
                                                 finishTransactions: false,
                                                 bundle: self.mockBundle)
        self.receiptFetcher = ReceiptFetcher(requestFetcher: self.mockRequestFetcher, systemInfo: self.mockSystemInfo)
    }

    func testReceiptDataWithRefreshPolicyNeverReturnsReceiptData() {
        var completionCalled = false
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .never) { data in
            completionCalled = true
            receivedData = data
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedData).toNot(beNil())
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyReturnsReceiptData() {
        var completionCalled = false
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { data in
            completionCalled = true
            receivedData = data
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedData).toNot(beNil())
    }

    func testReceiptDataWithRefreshPolicyAlwaysReturnsReceiptData() {
        var completionCalled = false
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .always) { data in
            completionCalled = true
            receivedData = data
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedData).toNot(beNil())
    }

    func testReceiptDataWithRefreshPolicyNeverDoesntRefreshIfEmpty() {
        var completionCalled = false
        mockBundle.receiptURLResult = .emptyReceipt
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .never) { data in
            completionCalled = true
            receivedData = data
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == false
        expect(receivedData).to(beNil())
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyRefreshesIfEmpty() {
        var completionCalled = false
        mockBundle.receiptURLResult = .emptyReceipt
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { data in
            completionCalled = true
            receivedData = data
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == true
        expect(receivedData).toNot(beNil())
        expect(receivedData).to(beEmpty())
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyRefreshesIfNil() {
        var completionCalled = false
        mockBundle.receiptURLResult = .nilURL
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { data in
            completionCalled = true
            receivedData = data
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == true
        expect(receivedData).toNot(beNil())
        expect(receivedData).to(beEmpty())
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyDoesntRefreshIfTheresData() {
        var completionCalled = false
        mockBundle.receiptURLResult = .receiptWithData
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { data in
            completionCalled = true
            receivedData = data
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == false
        expect(receivedData).toNot(beNil())
        expect(receivedData).toNot(beEmpty())
    }

    func testReceiptDataWithRefreshPolicyAlwaysRefreshesEvenIfTheresData() {
        var completionCalled = false
        mockBundle.receiptURLResult = .receiptWithData
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .always) { data in
            completionCalled = true
            receivedData = data
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == true
        expect(receivedData).toNot(beNil())
        expect(receivedData).toNot(beEmpty())
    }

    // MARK: - Receipt URL

    func testNoReceiptURLIfBundleDoesNotHaveOne() {
        self.mockBundle.receiptURLResult = .nilURL

        expect(self.receiptFetcher.receiptURL).to(beNil())
    }

    func testReceiptURLIsUnchangedInSandboxOnOlderVersionsIfNotWatchOS() throws {
        #if os(watchOS)
            throw XCTSkip("Test designed for any platform but watchOS")
        #endif

        self.mockBundle.receiptURLResult = .sandboxReceipt
        self.mockSystemInfo.stubbedIsSandbox = true

        self.mockSystemInfo.stubbedCurrentOperatingSystemVersion = .init(majorVersion: 6,
                                                                         minorVersion: 0,
                                                                         patchVersion: 0)

        let appStoreReceiptURL = try XCTUnwrap(self.mockBundle.appStoreReceiptURL)
        let url = try XCTUnwrap(self.receiptFetcher.receiptURL)

        expect(url) == appStoreReceiptURL
    }

    func testWatchOSReceiptURLIsUnchangedInProduction() throws {
        self.mockBundle.receiptURLResult = .receiptWithData
        self.mockSystemInfo.stubbedIsSandbox = false

        let appStoreReceiptURL = try XCTUnwrap(self.mockBundle.appStoreReceiptURL)
        let url = self.receiptFetcher.watchOSReceiptURL(appStoreReceiptURL)

        expect(url) == appStoreReceiptURL
    }

    func testWatchOSReceiptURLIsUnchangedInNewerVersions() throws {
        self.mockBundle.receiptURLResult = .sandboxReceipt
        self.mockSystemInfo.stubbedIsSandbox = true

        self.mockSystemInfo.stubbedCurrentOperatingSystemVersion = .init(majorVersion: 7,
                                                                         minorVersion: 1,
                                                                         patchVersion: 0)

        let appStoreReceiptURL = try XCTUnwrap(self.mockBundle.appStoreReceiptURL)
        let url = try XCTUnwrap(self.receiptFetcher.watchOSReceiptURL(appStoreReceiptURL))

        expect(url) == appStoreReceiptURL
    }

    func testWatchOSReceiptURLEndsOnReceiptOnOlderVersions() throws {
        self.mockBundle.receiptURLResult = .sandboxReceipt
        self.mockSystemInfo.stubbedIsSandbox = true

        self.mockSystemInfo.stubbedCurrentOperatingSystemVersion = .init(majorVersion: 6,
                                                                         minorVersion: 4,
                                                                         patchVersion: 2)

        let appStoreReceiptURL = try XCTUnwrap(self.mockBundle.appStoreReceiptURL)
        let url = try XCTUnwrap(self.receiptFetcher.watchOSReceiptURL(appStoreReceiptURL))

        expect(url) != appStoreReceiptURL
        expect(url.absoluteString).toNot(contain("sandboxReceipt"))
        expect(url.absoluteString).to(contain("receipt"))
    }

}
