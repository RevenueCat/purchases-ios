//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBundleURLBatcherTests.swift
//
//  Created by Jacob Zivan Rakidzich on 8/14/26.

@preconcurrency import Combine
import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
final class WebBundleURLBatcherTests: TestCase {

    private var bus: WebBundleEventBus!
    private var batcher: WebBundleURLBatcher!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        self.bus = WebBundleEventBus()
        self.batcher = WebBundleURLBatcher(eventBus: self.bus)
        self.cancellables = []
    }

    override func tearDown() {
        self.cancellables = nil
        self.batcher = nil
        self.bus = nil

        super.tearDown()
    }

    // MARK: - Target offerings

    func testTargetOfferingIdsAreCurrentThenPlacementsThenFallback() {
        let offerings = Self.offerings(
            currentOfferingID: "default",
            offeringIDs: ["default", "onboarding", "settings", "fallback", "unused"],
            placements: .init(
                fallbackOfferingId: "fallback",
                offeringIdsByPlacement: [
                    "settings": "settings",
                    "onboarding": "onboarding"
                ]
            )
        )

        expect(WebBundleURLBatcher.targetOfferingIds(from: offerings)) == [
            "default", "onboarding", "settings", "fallback"
        ]
    }

    func testTargetOfferingIdsSkipNullPlacementsAndDedupFirstWins() {
        let offerings = Self.offerings(
            currentOfferingID: "default",
            offeringIDs: ["default", "onboarding"],
            placements: .init(
                fallbackOfferingId: "default",
                offeringIdsByPlacement: [
                    "onboarding": "onboarding",
                    "settings": nil
                ]
            )
        )

        expect(WebBundleURLBatcher.targetOfferingIds(from: offerings)) == ["default", "onboarding"]
    }

    func testTargetOfferingIdsKeepMissingOfferingIds() {
        let offerings = Self.offerings(
            currentOfferingID: "missing-current",
            offeringIDs: ["onboarding"],
            placements: .init(
                fallbackOfferingId: "missing-fallback",
                offeringIdsByPlacement: ["onboarding": "onboarding"]
            )
        )

        expect(WebBundleURLBatcher.targetOfferingIds(from: offerings)) == [
            "missing-current", "onboarding", "missing-fallback"
        ]
    }

    func testTargetOfferingIdsSortPlacementsAlphabeticallyByKey() {
        let offerings = Self.offerings(
            currentOfferingID: "default",
            offeringIDs: ["default", "zebra", "alpha"],
            placements: .init(
                fallbackOfferingId: "fallback",
                offeringIdsByPlacement: [
                    "zebra": "zebra",
                    "alpha": "alpha"
                ]
            )
        )

        expect(WebBundleURLBatcher.targetOfferingIds(from: offerings)) == [
            "default", "alpha", "zebra", "fallback"
        ]
    }

    // MARK: - Screen visit order

    func testScreenVisitOrderFollowsStepGraphNotKeysOrDisplayNames() throws {
        // Screen keys are opaque `pw…` IDs; alphabetically the second screen sorts first.
        // Display names are also inverted so neither keys nor names encode visit order.
        let workflow = try Self.workflowFromJSON(
            id: "wf_paywall",
            screensJSON: """
            "\(Self.secondScreenId)": \(Self.screenJSON(
                name: "Screen 1",
                url: "https://example.com/second"
            )),
            "\(Self.firstScreenId)": \(Self.screenJSON(
                name: "Screen 2",
                url: "https://example.com/first"
            ))
            """,
            stepsJSON: """
            "\(Self.firstStepId)": {
              "id": "\(Self.firstStepId)",
              "type": "screen",
              "screen_id": "\(Self.firstScreenId)",
              "trigger_actions": {
                "continue": { "type": "step", "step_id": "\(Self.secondStepId)" }
              }
            },
            "\(Self.secondStepId)": {
              "id": "\(Self.secondStepId)",
              "type": "screen",
              "screen_id": "\(Self.secondScreenId)",
              "trigger_actions": {}
            }
            """,
            initialStepId: Self.firstStepId
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(Self.webViewURLs(in: screens)) == [
            "https://example.com/first",
            "https://example.com/second"
        ]
        expect(screens.compactMap(\.name)) == ["Screen 2", "Screen 1"]
    }

    func testSingleStepFallbackIsASecondRoot() throws {
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "\(Self.secondScreenId)": \(Self.screenJSON(name: "Exit", url: "https://example.com/exit")),
            "\(Self.firstScreenId)": \(Self.screenJSON(name: "Main", url: "https://example.com/main"))
            """,
            stepsJSON: """
            "\(Self.firstStepId)": {
              "id": "\(Self.firstStepId)",
              "type": "screen",
              "screen_id": "\(Self.firstScreenId)"
            },
            "\(Self.secondStepId)": {
              "id": "\(Self.secondStepId)",
              "type": "screen",
              "screen_id": "\(Self.secondScreenId)"
            }
            """,
            initialStepId: Self.firstStepId,
            singleStepFallbackId: Self.secondStepId
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(Self.webViewURLs(in: screens)) == [
            "https://example.com/main",
            "https://example.com/exit"
        ]
    }

    func testTriggerActionsAreFollowedWhenTriggersArrayIsEmpty() throws {
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "\(Self.secondScreenId)": \(Self.screenJSON(name: "Next", url: "https://example.com/next")),
            "\(Self.firstScreenId)": \(Self.screenJSON(name: "Start", url: "https://example.com/start"))
            """,
            stepsJSON: """
            "\(Self.firstStepId)": {
              "id": "\(Self.firstStepId)",
              "type": "screen",
              "screen_id": "\(Self.firstScreenId)",
              "trigger_actions": {
                "some_button_action": { "type": "step", "step_id": "\(Self.secondStepId)" }
              }
            },
            "\(Self.secondStepId)": {
              "id": "\(Self.secondStepId)",
              "type": "screen",
              "screen_id": "\(Self.secondScreenId)",
              "trigger_actions": {}
            }
            """,
            initialStepId: Self.firstStepId
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(Self.webViewURLs(in: screens)) == [
            "https://example.com/start",
            "https://example.com/next"
        ]
    }

    func testDeclaredTriggersAreFollowedBeforeUnreferencedActions() throws {
        let thirdScreenId = "pw0aaaaaaaaaaaaaaa"
        let thirdStepId = "kLmNpQr"
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "\(thirdScreenId)": \(Self.screenJSON(name: "C", url: "https://example.com/c")),
            "\(Self.secondScreenId)": \(Self.screenJSON(name: "B", url: "https://example.com/b")),
            "\(Self.firstScreenId)": \(Self.screenJSON(name: "A", url: "https://example.com/a"))
            """,
            stepsJSON: """
            "\(Self.firstStepId)": {
              "id": "\(Self.firstStepId)",
              "type": "screen",
              "screen_id": "\(Self.firstScreenId)",
              "triggers": [{ "type": "on_press", "action_id": "to_b" }],
              "trigger_actions": {
                "hidden": { "type": "step", "step_id": "\(thirdStepId)" },
                "to_b": { "type": "step", "step_id": "\(Self.secondStepId)" }
              }
            },
            "\(Self.secondStepId)": {
              "id": "\(Self.secondStepId)",
              "type": "screen",
              "screen_id": "\(Self.secondScreenId)"
            },
            "\(thirdStepId)": {
              "id": "\(thirdStepId)",
              "type": "screen",
              "screen_id": "\(thirdScreenId)"
            }
            """,
            initialStepId: Self.firstStepId
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(Self.webViewURLs(in: screens)) == [
            "https://example.com/a",
            "https://example.com/b",
            "https://example.com/c"
        ]
    }

    func testUnknownActionsDoNotHideAFollowingStep() throws {
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "\(Self.secondScreenId)": \(Self.screenJSON(name: "B", url: "https://example.com/b")),
            "\(Self.firstScreenId)": \(Self.screenJSON(name: "A", url: "https://example.com/a"))
            """,
            stepsJSON: """
            "\(Self.firstStepId)": {
              "id": "\(Self.firstStepId)",
              "type": "screen",
              "screen_id": "\(Self.firstScreenId)",
              "triggers": [
                { "type": "on_press", "action_id": "unknown" },
                { "type": "on_press", "action_id": "to_b" }
              ],
              "trigger_actions": {
                "unknown": { "type": "close" },
                "to_b": { "type": "step", "step_id": "\(Self.secondStepId)" }
              }
            },
            "\(Self.secondStepId)": {
              "id": "\(Self.secondStepId)",
              "type": "screen",
              "screen_id": "\(Self.secondScreenId)"
            }
            """,
            initialStepId: Self.firstStepId
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(Self.webViewURLs(in: screens)) == [
            "https://example.com/a",
            "https://example.com/b"
        ]
    }

    func testFirstVisitWinsForCyclesAndSharedScreens() throws {
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "\(Self.secondScreenId)": \(Self.screenJSON(name: "B", url: "https://example.com/b")),
            "\(Self.firstScreenId)": \(Self.screenJSON(name: "A", url: "https://example.com/a"))
            """,
            stepsJSON: """
            "\(Self.firstStepId)": {
              "id": "\(Self.firstStepId)",
              "type": "screen",
              "screen_id": "\(Self.firstScreenId)",
              "trigger_actions": { "to_b": { "type": "step", "step_id": "\(Self.secondStepId)" } }
            },
            "\(Self.secondStepId)": {
              "id": "\(Self.secondStepId)",
              "type": "screen",
              "screen_id": "\(Self.secondScreenId)",
              "trigger_actions": { "back": { "type": "step", "step_id": "\(Self.firstStepId)" } }
            }
            """,
            initialStepId: Self.firstStepId
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(Self.webViewURLs(in: screens)) == [
            "https://example.com/a",
            "https://example.com/b"
        ]
    }

    func testUnreachedScreensAreNotIncluded() throws {
        let orphanScreenId = "pwffffffffffffffff"
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "\(orphanScreenId)": \(Self.screenJSON(name: "Orphan", url: "https://example.com/orphan")),
            "\(Self.firstScreenId)": \(Self.screenJSON(name: "Reachable", url: "https://example.com/reachable"))
            """,
            stepsJSON: """
            "\(Self.firstStepId)": {
              "id": "\(Self.firstStepId)",
              "type": "screen",
              "screen_id": "\(Self.firstScreenId)"
            }
            """,
            initialStepId: Self.firstStepId
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(Self.webViewURLs(in: screens)) == ["https://example.com/reachable"]
    }

    func testUnreachableInitialStepYieldsNoScreens() throws {
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "\(Self.secondScreenId)": \(Self.screenJSON(name: "B", url: "https://example.com/b")),
            "\(Self.firstScreenId)": \(Self.screenJSON(name: "A", url: "https://example.com/a"))
            """,
            stepsJSON: """
            "missing": { "id": "missing", "type": "screen", "screen_id": "no-such-screen" }
            """,
            initialStepId: "missing"
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(screens).to(beEmpty())
    }

    // MARK: - URL selection

    func testWorkedExampleWarmOrder() throws {
        let paywall = try Self.linearWorkflow(
            id: "wf_paywall",
            firstURLs: ["https://example.com/paywall/first"],
            secondURLs: ["https://example.com/paywall/second"]
        )
        let onboarding = try Self.singleScreenWorkflow(
            id: "wf_onboarding",
            url: "https://example.com/onboarding/welcome"
        )

        let offerings = Self.offerings(
            currentOfferingID: "default",
            offeringIDs: ["default", "onboarding"],
            placements: .init(
                fallbackOfferingId: "default",
                offeringIdsByPlacement: [
                    "onboarding": "onboarding",
                    "settings": nil
                ]
            )
        )

        let urls = WebBundleURLBatcher.orderedWebViewURLs(
            offerings: offerings,
            workflowsByOfferingId: [
                "default": paywall,
                "onboarding": onboarding
            ]
        )

        expect(urls.map(\.url.absoluteString)) == [
            "https://example.com/paywall/first",
            "https://example.com/paywall/second",
            "https://example.com/onboarding/welcome"
        ]
    }

    func testPrefetchOnlyWorkflowIsNotSelected() throws {
        let prefetch = try Self.singleScreenWorkflow(id: "wf_prefetch", url: "https://example.com/prefetch")
        let current = try Self.singleScreenWorkflow(id: "wf_current", url: "https://example.com/current")

        let offerings = Self.offerings(currentOfferingID: "default", offeringIDs: ["default", "other"])
        let urls = WebBundleURLBatcher.orderedWebViewURLs(
            offerings: offerings,
            workflowsByOfferingId: [
                "default": current,
                "other": prefetch
            ]
        )

        expect(urls.map(\.url.absoluteString)) == ["https://example.com/current"]
    }

    func testSameWorkflowBehindSeveralOfferingsIsEnqueuedOnce() throws {
        let shared = try Self.singleScreenWorkflow(id: "wf_shared", url: "https://example.com/shared")
        let offerings = Self.offerings(
            currentOfferingID: "default",
            offeringIDs: ["default", "onboarding"],
            placements: .init(
                fallbackOfferingId: nil,
                offeringIdsByPlacement: ["onboarding": "onboarding"]
            )
        )

        let urls = WebBundleURLBatcher.orderedWebViewURLs(
            offerings: offerings,
            workflowsByOfferingId: [
                "default": shared,
                "onboarding": shared
            ]
        )

        expect(urls.map(\.url.absoluteString)) == ["https://example.com/shared"]
    }

    func testInlineV2TreeIsUsedWhenOfferingHasNoWorkflow() {
        let offering = Self.offering(
            id: "default",
            webViewURL: "https://example.com/inline"
        )
        let offerings = Self.offerings(currentOfferingID: "default", offerings: [offering])

        let urls = WebBundleURLBatcher.orderedWebViewURLs(
            offerings: offerings,
            workflowsByOfferingId: [:]
        )

        expect(urls.map(\.url.absoluteString)) == ["https://example.com/inline"]
    }

    func testV1OnlyOfferingContributesNothing() {
        let offerings = Self.offerings(currentOfferingID: "default", offeringIDs: ["default"])
        let urls = WebBundleURLBatcher.orderedWebViewURLs(
            offerings: offerings,
            workflowsByOfferingId: [:]
        )
        expect(urls).to(beEmpty())
    }

    func testDuplicateURLsKeepFirstOccurrence() throws {
        let workflow = try Self.linearWorkflow(
            id: "wf",
            firstURLs: ["https://example.com/same"],
            secondURLs: ["https://example.com/same"]
        )
        let offerings = Self.offerings(currentOfferingID: "default", offeringIDs: ["default"])

        let urls = WebBundleURLBatcher.orderedWebViewURLs(
            offerings: offerings,
            workflowsByOfferingId: ["default": workflow]
        )

        expect(urls.map(\.url.absoluteString)) == ["https://example.com/same"]
    }

    func testScreenBatchesKeepEveryURLOnAScreenTogether() throws {
        let workflow = try Self.linearWorkflow(
            id: "wf",
            firstURLs: [
                "https://example.com/first/a",
                "https://example.com/first/b",
                "https://example.com/first/c"
            ],
            secondURLs: [
                "https://example.com/second/a",
                "https://example.com/second/b"
            ]
        )
        let offerings = Self.offerings(currentOfferingID: "default", offeringIDs: ["default"])

        let batches = WebBundleURLBatcher.orderedScreenURLBatches(
            offerings: offerings,
            workflowsByOfferingId: ["default": workflow]
        )

        expect(batches.map { $0.map(\.url.absoluteString) }) == [
            [
                "https://example.com/first/a",
                "https://example.com/first/b",
                "https://example.com/first/c"
            ],
            [
                "https://example.com/second/a",
                "https://example.com/second/b"
            ]
        ]
    }

    // MARK: - Publishing

    func testPublishSendsOneBatchPerScreenInVisitOrder() async throws {
        let workflow = try Self.linearWorkflow(
            id: "wf",
            firstURLs: [
                "https://example.com/first/a",
                "https://example.com/first/b",
                "https://example.com/first/c"
            ],
            secondURLs: [
                "https://example.com/second/a",
                "https://example.com/second/b"
            ]
        )
        let offerings = Self.offerings(currentOfferingID: "default", offeringIDs: ["default"])

        var received: [WebBundleEvent] = []
        self.bus.publisher
            .dropFirst()
            .sink { received.append($0) }
            .store(in: &self.cancellables)

        await self.batcher.publish(offerings: offerings, workflowsByOfferingId: ["default": workflow])

        expect(received) == [
            .receivedAssetURLs([
                Self.url("https://example.com/first/a"),
                Self.url("https://example.com/first/b"),
                Self.url("https://example.com/first/c")
            ]),
            .receivedAssetURLs([
                Self.url("https://example.com/second/a"),
                Self.url("https://example.com/second/b")
            ])
        ]
    }

    func testInlineOfferingIsOneScreenBatch() async {
        let offering = Self.offering(id: "default", webViewURLs: [
            "https://example.com/1",
            "https://example.com/2",
            "https://example.com/3"
        ])
        let offerings = Self.offerings(currentOfferingID: "default", offerings: [offering])

        var received: [WebBundleEvent] = []
        self.bus.publisher
            .dropFirst()
            .sink { received.append($0) }
            .store(in: &self.cancellables)

        await self.batcher.publish(offerings: offerings, workflowsByOfferingId: [:])

        expect(received) == [
            .receivedAssetURLs([
                Self.url("https://example.com/1"),
                Self.url("https://example.com/2"),
                Self.url("https://example.com/3")
            ])
        ]
    }

    func testPresentedWorkflowIsAppendedOnce() async throws {
        let current = try Self.singleScreenWorkflow(id: "wf_current", url: "https://example.com/current")
        let presented = try Self.singleScreenWorkflow(id: "wf_presented", url: "https://example.com/presented")
        let offerings = Self.offerings(currentOfferingID: "default", offeringIDs: ["default"])

        var received: [WebBundleEvent] = []
        self.bus.publisher
            .dropFirst()
            .sink { received.append($0) }
            .store(in: &self.cancellables)

        await self.batcher.publish(offerings: offerings, workflowsByOfferingId: ["default": current])
        await self.batcher.publishPresentedWorkflow(presented)
        await self.batcher.publishPresentedWorkflow(presented)

        expect(received) == [
            .receivedAssetURLs([Self.url("https://example.com/current")]),
            .receivedAssetURLs([Self.url("https://example.com/presented")])
        ]
    }

    func testEmptyPublishDoesNotClearLoadPathDedup() async throws {
        let current = try Self.singleScreenWorkflow(id: "wf_current", url: "https://example.com/current")
        let offerings = Self.offerings(currentOfferingID: "default", offeringIDs: ["default"])

        var received: [WebBundleEvent] = []
        self.bus.publisher
            .dropFirst()
            .sink { received.append($0) }
            .store(in: &self.cancellables)

        await self.batcher.publish(offerings: offerings, workflowsByOfferingId: ["default": current])
        await self.batcher.publish(offerings: offerings, workflowsByOfferingId: [:])
        await self.batcher.publishPresentedWorkflow(current)

        expect(received) == [
            .receivedAssetURLs([Self.url("https://example.com/current")])
        ]
    }

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private extension WebBundleURLBatcherTests {

    /// Opaque published screen IDs (`pw` + 16 hex chars). `secondScreenId` sorts before `firstScreenId`.
    static let firstScreenId = "pwa1b2c3d4e5f67890"
    static let secondScreenId = "pw9f8e7d6c5b4a3210"
    /// Opaque step nanoids. Unique within a workflow; not sequential names.
    static let firstStepId = "nQ8kT2w"
    static let secondStepId = "B7mF9qr"

    static func webViewURLs(in screens: [WorkflowScreen]) -> [String] {
        return screens.flatMap { $0.allCacheAssets.webBundles.map(\.url.absoluteString) }
    }

    static func singleScreenWorkflow(id: String, url: String) throws -> PublishedWorkflow {
        return try self.workflowFromJSON(
            id: id,
            screensJSON: """
            "\(self.firstScreenId)": \(self.screenJSON(name: "Screen", url: url))
            """,
            stepsJSON: """
            "\(self.firstStepId)": {
              "id": "\(self.firstStepId)",
              "type": "screen",
              "screen_id": "\(self.firstScreenId)"
            }
            """,
            initialStepId: self.firstStepId
        )
    }

    static func linearWorkflow(
        id: String,
        firstURLs: [String],
        secondURLs: [String]
    ) throws -> PublishedWorkflow {
        return try self.workflowFromJSON(
            id: id,
            screensJSON: """
            "\(self.secondScreenId)": \(self.screenJSON(name: "Screen 2", urls: secondURLs)),
            "\(self.firstScreenId)": \(self.screenJSON(name: "Screen 1", urls: firstURLs))
            """,
            stepsJSON: """
            "\(self.firstStepId)": {
              "id": "\(self.firstStepId)",
              "type": "screen",
              "screen_id": "\(self.firstScreenId)",
              "trigger_actions": {
                "continue": { "type": "step", "step_id": "\(self.secondStepId)" }
              }
            },
            "\(self.secondStepId)": {
              "id": "\(self.secondStepId)",
              "type": "screen",
              "screen_id": "\(self.secondScreenId)",
              "trigger_actions": {}
            }
            """,
            initialStepId: self.firstStepId
        )
    }

    static func offerings(
        currentOfferingID: String?,
        offeringIDs: [String],
        placements: Offerings.Placements? = nil
    ) -> Offerings {
        return self.offerings(
            currentOfferingID: currentOfferingID,
            offerings: offeringIDs.map { self.offering(id: $0) },
            placements: placements
        )
    }

    static func offerings(
        currentOfferingID: String?,
        offerings: [Offering],
        placements: Offerings.Placements? = nil
    ) -> Offerings {
        let response = OfferingsResponse(
            currentOfferingId: currentOfferingID,
            offerings: [],
            placements: nil,
            targeting: nil,
            uiConfig: nil
        )
        return Offerings(
            offerings: Dictionary(uniqueKeysWithValues: offerings.map { ($0.identifier, $0) }),
            currentOfferingID: currentOfferingID,
            placements: placements,
            targeting: nil,
            contents: .init(response: response, httpResponseOriginalSource: .mainServer),
            loadedFromDiskCache: false
        )
    }

    static func offering(id: String, webViewURL: String? = nil) -> Offering {
        return self.offering(id: id, webViewURLs: webViewURL.map { [$0] } ?? [])
    }

    static func offering(id: String, webViewURLs: [String]) -> Offering {
        let components: [PaywallComponent] = webViewURLs.enumerated().map { index, url in
            .webView(.init(id: "web-\(index)", protocolVersion: 1, url: url))
        }
        let paywallComponents: Offering.PaywallComponents?
        if components.isEmpty {
            paywallComponents = nil
        } else {
            paywallComponents = .init(
                uiConfig: .empty,
                data: .init(
                    templateName: "test",
                    assetBaseURL: URL(string: "https://assets.example.com")!,
                    componentsConfig: .init(base: .init(
                        stack: .init(components: components),
                        stickyFooter: nil,
                        background: .color(.init(light: .hex("#ffffff")))
                    )),
                    componentsLocalizations: [:],
                    revision: 1,
                    defaultLocaleIdentifier: "en_US"
                )
            )
        }
        return Offering(
            identifier: id,
            serverDescription: id,
            paywallComponents: paywallComponents,
            availablePackages: [],
            webCheckoutUrl: nil
        )
    }

    static func workflowFromJSON(
        id: String,
        screensJSON: String,
        stepsJSON: String,
        initialStepId: String,
        singleStepFallbackId: String? = nil
    ) throws -> PublishedWorkflow {
        let fallback = singleStepFallbackId.map { ", \"single_step_fallback_id\": \"\($0)\"" } ?? ""
        let json = """
        {
          "id": "\(id)",
          "display_name": "\(id)",
          "initial_step_id": "\(initialStepId)"\(fallback),
          "steps": { \(stepsJSON) },
          "screens": { \(screensJSON) }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
    }

    static func screenJSON(name: String, url: String) -> String {
        return self.screenJSON(name: name, urls: [url])
    }

    static func screenJSON(name: String, urls: [String]) -> String {
        let components = urls.enumerated().map { index, url in
            """
            {
              "type": "web_view",
              "id": "web-\(index)",
              "protocol_version": 1,
              "url": "\(url)",
              "size": { "width": { "type": "fill" }, "height": { "type": "fill" } }
            }
            """
        }.joined(separator: ",\n")
        return """
        {
          "name": "\(name)",
          "template_name": "tmpl",
          "asset_base_url": "https://assets.revenuecat.com",
          "default_locale": "en_US",
          "components_localizations": {},
          "components_config": {
            "base": {
              "stack": {
                "type": "stack",
                "components": [
                  \(components)
                ],
                "dimension": { "type": "vertical", "alignment": "center", "distribution": "center" },
                "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
                "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
                "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
              },
              "background": {
                "type": "color",
                "value": { "light": { "type": "hex", "value": "#FFFFFF" } }
              }
            }
          },
          "offering_identifier": "default"
        }
        """
    }

    static func url(_ string: String) -> URLWithValidation {
        return .init(url: URL(string: string)!, checksum: nil)
    }

}
