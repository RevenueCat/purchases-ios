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

    func testScreenVisitOrderFollowsStepGraphNotJSONObjectOrder() throws {
        let workflow = try Self.workflowFromJSON(
            id: "wf_paywall",
            screensJSON: """
            "page2": \(Self.screenJSON(url: "https://example.com/page2")),
            "page1": \(Self.screenJSON(url: "https://example.com/page1"))
            """,
            stepsJSON: """
            "step1": {
              "id": "step1",
              "type": "screen",
              "screen_id": "page1",
              "triggers": [{ "type": "on_press", "action_id": "next" }],
              "trigger_actions": { "next": { "type": "step", "step_id": "step2" } }
            },
            "step2": { "id": "step2", "type": "screen", "screen_id": "page2" }
            """,
            initialStepId: "step1"
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(screens.compactMap(\.name)) == ["page1", "page2"]
    }

    func testSingleStepFallbackIsASecondRoot() throws {
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "main": \(Self.screenJSON(url: "https://example.com/main")),
            "exit": \(Self.screenJSON(url: "https://example.com/exit"))
            """,
            stepsJSON: """
            "main": { "id": "main", "type": "screen", "screen_id": "main" },
            "exit": { "id": "exit", "type": "screen", "screen_id": "exit" }
            """,
            initialStepId: "main",
            singleStepFallbackId: "exit"
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(screens.compactMap(\.name)) == ["main", "exit"]
    }

    func testUnreferencedTriggerActionsAreFollowedAfterDeclaredTriggers() throws {
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "a": \(Self.screenJSON(url: "https://example.com/a")),
            "b": \(Self.screenJSON(url: "https://example.com/b")),
            "c": \(Self.screenJSON(url: "https://example.com/c"))
            """,
            stepsJSON: """
            "a": {
              "id": "a",
              "type": "screen",
              "screen_id": "a",
              "triggers": [{ "type": "on_press", "action_id": "to_b" }],
              "trigger_actions": {
                "hidden": { "type": "step", "step_id": "c" },
                "to_b": { "type": "step", "step_id": "b" }
              }
            },
            "b": { "id": "b", "type": "screen", "screen_id": "b" },
            "c": { "id": "c", "type": "screen", "screen_id": "c" }
            """,
            initialStepId: "a"
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(screens.compactMap(\.name)) == ["a", "b", "c"]
    }

    func testUnknownActionsDoNotHideAFollowingStep() throws {
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "a": \(Self.screenJSON(url: "https://example.com/a")),
            "b": \(Self.screenJSON(url: "https://example.com/b"))
            """,
            stepsJSON: """
            "a": {
              "id": "a",
              "type": "screen",
              "screen_id": "a",
              "triggers": [
                { "type": "on_press", "action_id": "unknown" },
                { "type": "on_press", "action_id": "to_b" }
              ],
              "trigger_actions": {
                "unknown": { "type": "close" },
                "to_b": { "type": "step", "step_id": "b" }
              }
            },
            "b": { "id": "b", "type": "screen", "screen_id": "b" }
            """,
            initialStepId: "a"
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(screens.compactMap(\.name)) == ["a", "b"]
    }

    func testFirstVisitWinsForCyclesAndSharedScreens() throws {
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "a": \(Self.screenJSON(url: "https://example.com/a")),
            "b": \(Self.screenJSON(url: "https://example.com/b"))
            """,
            stepsJSON: """
            "a": {
              "id": "a",
              "type": "screen",
              "screen_id": "a",
              "triggers": [{ "type": "on_press", "action_id": "to_b" }],
              "trigger_actions": { "to_b": { "type": "step", "step_id": "b" } }
            },
            "b": {
              "id": "b",
              "type": "screen",
              "screen_id": "b",
              "triggers": [{ "type": "on_press", "action_id": "back" }],
              "trigger_actions": { "back": { "type": "step", "step_id": "a" } }
            }
            """,
            initialStepId: "a"
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(screens.compactMap(\.name)) == ["a", "b"]
    }

    func testUnreachedScreensAreAppendedInAlphabeticalOrder() throws {
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "orphan2": \(Self.screenJSON(url: "https://example.com/orphan2")),
            "page1": \(Self.screenJSON(url: "https://example.com/page1")),
            "orphan1": \(Self.screenJSON(url: "https://example.com/orphan1"))
            """,
            stepsJSON: """
            "page1": { "id": "page1", "type": "screen", "screen_id": "page1" }
            """,
            initialStepId: "page1"
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(screens.compactMap(\.name)) == ["page1", "orphan1", "orphan2"]
    }

    func testMissingWalkUsesAlphabeticalScreenOrder() throws {
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "c": \(Self.screenJSON(url: "https://example.com/c")),
            "a": \(Self.screenJSON(url: "https://example.com/a")),
            "b": \(Self.screenJSON(url: "https://example.com/b"))
            """,
            stepsJSON: """
            "missing": { "id": "missing", "type": "screen", "screen_id": "no-such-screen" }
            """,
            initialStepId: "missing"
        )

        let screens = WebBundleURLBatcher.screensInVisitOrder(for: workflow)
        expect(screens.compactMap(\.name)) == ["a", "b", "c"]
    }

    // MARK: - URL selection

    func testWorkedExampleWarmOrder() throws {
        let paywall = try Self.workflowFromJSON(
            id: "wf_paywall",
            screensJSON: """
            "page2": \(Self.screenJSON(url: "https://example.com/paywall/page2")),
            "page1": \(Self.screenJSON(url: "https://example.com/paywall/page1"))
            """,
            stepsJSON: """
            "page1": {
              "id": "page1",
              "type": "screen",
              "screen_id": "page1",
              "triggers": [{ "type": "on_press", "action_id": "next" }],
              "trigger_actions": { "next": { "type": "step", "step_id": "page2" } }
            },
            "page2": { "id": "page2", "type": "screen", "screen_id": "page2" }
            """,
            initialStepId: "page1"
        )
        let onboarding = try Self.workflowFromJSON(
            id: "wf_onboarding",
            screensJSON: """
            "welcome": \(Self.screenJSON(url: "https://example.com/onboarding/welcome"))
            """,
            stepsJSON: """
            "welcome": { "id": "welcome", "type": "screen", "screen_id": "welcome" }
            """,
            initialStepId: "welcome"
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
            "https://example.com/paywall/page1",
            "https://example.com/paywall/page2",
            "https://example.com/onboarding/welcome"
        ]
    }

    func testPrefetchOnlyWorkflowIsNotSelected() throws {
        let prefetch = try Self.workflowFromJSON(
            id: "wf_prefetch",
            screensJSON: """
            "only": \(Self.screenJSON(url: "https://example.com/prefetch"))
            """,
            stepsJSON: """
            "only": { "id": "only", "type": "screen", "screen_id": "only" }
            """,
            initialStepId: "only"
        )
        let current = try Self.workflowFromJSON(
            id: "wf_current",
            screensJSON: """
            "only": \(Self.screenJSON(url: "https://example.com/current"))
            """,
            stepsJSON: """
            "only": { "id": "only", "type": "screen", "screen_id": "only" }
            """,
            initialStepId: "only"
        )

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
        let shared = try Self.workflowFromJSON(
            id: "wf_shared",
            screensJSON: """
            "only": \(Self.screenJSON(url: "https://example.com/shared"))
            """,
            stepsJSON: """
            "only": { "id": "only", "type": "screen", "screen_id": "only" }
            """,
            initialStepId: "only"
        )
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
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "a": \(Self.screenJSON(url: "https://example.com/same")),
            "b": \(Self.screenJSON(url: "https://example.com/same"))
            """,
            stepsJSON: """
            "a": {
              "id": "a",
              "type": "screen",
              "screen_id": "a",
              "triggers": [{ "type": "on_press", "action_id": "next" }],
              "trigger_actions": { "next": { "type": "step", "step_id": "b" } }
            },
            "b": { "id": "b", "type": "screen", "screen_id": "b" }
            """,
            initialStepId: "a"
        )
        let offerings = Self.offerings(currentOfferingID: "default", offeringIDs: ["default"])

        let urls = WebBundleURLBatcher.orderedWebViewURLs(
            offerings: offerings,
            workflowsByOfferingId: ["default": workflow]
        )

        expect(urls.map(\.url.absoluteString)) == ["https://example.com/same"]
    }

    func testScreenBatchesKeepEveryURLOnAScreenTogether() throws {
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "page2": \(Self.screenJSON(urls: [
                "https://example.com/page2/a",
                "https://example.com/page2/b"
            ])),
            "page1": \(Self.screenJSON(urls: [
                "https://example.com/page1/a",
                "https://example.com/page1/b",
                "https://example.com/page1/c"
            ]))
            """,
            stepsJSON: """
            "page1": {
              "id": "page1",
              "type": "screen",
              "screen_id": "page1",
              "triggers": [{ "type": "on_press", "action_id": "next" }],
              "trigger_actions": { "next": { "type": "step", "step_id": "page2" } }
            },
            "page2": { "id": "page2", "type": "screen", "screen_id": "page2" }
            """,
            initialStepId: "page1"
        )
        let offerings = Self.offerings(currentOfferingID: "default", offeringIDs: ["default"])

        let batches = WebBundleURLBatcher.orderedScreenURLBatches(
            offerings: offerings,
            workflowsByOfferingId: ["default": workflow]
        )

        expect(batches.map { $0.map(\.url.absoluteString) }) == [
            [
                "https://example.com/page1/a",
                "https://example.com/page1/b",
                "https://example.com/page1/c"
            ],
            [
                "https://example.com/page2/a",
                "https://example.com/page2/b"
            ]
        ]
    }

    // MARK: - Publishing

    func testPublishSendsOneBatchPerScreenInVisitOrder() async throws {
        let workflow = try Self.workflowFromJSON(
            id: "wf",
            screensJSON: """
            "page2": \(Self.screenJSON(urls: [
                "https://example.com/page2/a",
                "https://example.com/page2/b"
            ])),
            "page1": \(Self.screenJSON(urls: [
                "https://example.com/page1/a",
                "https://example.com/page1/b",
                "https://example.com/page1/c"
            ]))
            """,
            stepsJSON: """
            "page1": {
              "id": "page1",
              "type": "screen",
              "screen_id": "page1",
              "triggers": [{ "type": "on_press", "action_id": "next" }],
              "trigger_actions": { "next": { "type": "step", "step_id": "page2" } }
            },
            "page2": { "id": "page2", "type": "screen", "screen_id": "page2" }
            """,
            initialStepId: "page1"
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
                Self.url("https://example.com/page1/a"),
                Self.url("https://example.com/page1/b"),
                Self.url("https://example.com/page1/c")
            ]),
            .receivedAssetURLs([
                Self.url("https://example.com/page2/a"),
                Self.url("https://example.com/page2/b")
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
        let current = try Self.workflowFromJSON(
            id: "wf_current",
            screensJSON: """
            "only": \(Self.screenJSON(url: "https://example.com/current"))
            """,
            stepsJSON: """
            "only": { "id": "only", "type": "screen", "screen_id": "only" }
            """,
            initialStepId: "only"
        )
        let presented = try Self.workflowFromJSON(
            id: "wf_presented",
            screensJSON: """
            "only": \(Self.screenJSON(url: "https://example.com/presented"))
            """,
            stepsJSON: """
            "only": { "id": "only", "type": "screen", "screen_id": "only" }
            """,
            initialStepId: "only"
        )
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

}

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
private extension WebBundleURLBatcherTests {

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

    static func screenJSON(url: String) -> String {
        return self.screenJSON(urls: [url])
    }

    static func screenJSON(urls: [String]) -> String {
        let components = urls.enumerated().map { index, url in
            """
            {
              "type": "web_view",
              "id": "web-\(index)",
              "protocol_version": 1,
              "url": "\(url)",
              "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
            }
            """
        }.joined(separator: ",\n")
        let name = urls.first.flatMap { URL(string: $0)?.lastPathComponent } ?? "screen"
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
