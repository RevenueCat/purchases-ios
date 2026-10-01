//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBundleEventBusTests.swift
//
//  Created by Jacob Zivan Rakidzich on 8/6/26.

@preconcurrency import Combine
import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
final class WebBundleEventBusTests: TestCase {

    private var bus: WebBundleEventBus!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        self.bus = WebBundleEventBus()
        self.cancellables = []
    }

    override func tearDown() {
        self.cancellables = nil
        self.bus = nil

        super.tearDown()
    }

    func testLateSubscriberReceivesLastPublishedURLs() async {
        let urls: [URLWithValidation] = [
            .init(url: URL(string: "https://example.com/a")!, checksum: nil),
            .init(url: URL(string: "https://example.com/b")!, checksum: nil)
        ]
        await self.bus.publish(urls)

        var received: WebBundleEvent?
        self.bus.publisher
            .sink { received = $0 }
            .store(in: &self.cancellables)

        expect(received) == .receivedAssetURLs(urls)
    }

    func testPublishingReplacesPreviousValueForSubsequentSubscribers() async {
        let first: [URLWithValidation] = [
            .init(url: URL(string: "https://example.com/first")!, checksum: nil)
        ]
        let second: [URLWithValidation] = [
            .init(url: URL(string: "https://example.com/second")!, checksum: nil)
        ]

        await self.bus.publish(first)
        await self.bus.publish(second)

        var received: WebBundleEvent?
        self.bus.publisher
            .sink { received = $0 }
            .store(in: &self.cancellables)

        expect(received) == .receivedAssetURLs(second)
    }

    func testInitialSubscriberReceivesEmpty() {
        var received: WebBundleEvent?
        self.bus.publisher
            .sink { received = $0 }
            .store(in: &self.cancellables)

        expect(received) == .empty
    }

    func testClearCache() async {
        await self.bus.clearCache()

        var received: WebBundleEvent?
        self.bus.publisher
            .sink { received = $0 }
            .store(in: &self.cancellables)
        expect(received) == .cacheClearRequested
    }

    func testEmptyReplacesCurrentValueWithEmpty() async {
        let urls: [URLWithValidation] = [
            .init(url: URL(string: "https://example.com/a")!, checksum: nil),
            .init(url: URL(string: "https://example.com/b")!, checksum: nil)
        ]
        let bus = self.bus!
        await bus.publish(urls)

        await bus.empty()

        var received: WebBundleEvent?
        bus.publisher
            .sink { received = $0 }
            .store(in: &self.cancellables)

        expect(received) == .empty
    }

    func testSubscriberCanPublishInResponseToValue() async {
        let first: [URLWithValidation] = [
            .init(url: URL(string: "https://example.com/first")!, checksum: nil)
        ]
        let second: [URLWithValidation] = [
            .init(url: URL(string: "https://example.com/second")!, checksum: nil)
        ]
        let receivedSecond = self.expectation(description: "Received second publication")
        let bus = self.bus!

        bus.publisher
            .dropFirst()
            .sink { event in
                if event == .receivedAssetURLs(first) {
                    Task {
                        await bus.publish(second)
                    }
                } else if event == .receivedAssetURLs(second) {
                    receivedSecond.fulfill()
                }
            }
            .store(in: &self.cancellables)

        await bus.publish(first)
        await self.fulfillment(of: [receivedSecond], timeout: 1)
    }

}
