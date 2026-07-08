import Foundation

/// Generates the wire payloads the fixture server responds with: the legacy offerings JSON,
/// the `/v1/config/{domain}` RC-Container, and the content-addressed blobs it references.
/// All payloads are deterministic for a given (paywallCount, workflowCount), so byte counts
/// are comparable across runs and branches.
struct BenchmarkPayloadFactory {

    static let blobURLFormat = "https://cdn.revenuecat.local/blobs/{blob_ref}"

    let configManifest = "benchmark-manifest-v1"

    let offeringsData: Data
    let configContainerData: Data

    private let blobsByRef: [String: Data]

    init(paywallCount: Int, workflowCount: Int) {
        let builder = PayloadBuilder(paywallCount: paywallCount, workflowCount: workflowCount)
        self.offeringsData = builder.offeringsData()

        var blobs: [String: Data] = [:]
        var workflowRefs: [String: String] = [:]
        for index in 0..<workflowCount {
            let blob = builder.workflowBlobData(index: index)
            let ref = RCContainerEncoder.blobRef(for: blob)
            blobs[ref] = blob
            workflowRefs["workflow_\(index)"] = ref
        }

        let uiConfigAppBlob = builder.uiConfigAppBlobData()
        let uiConfigAppRef = RCContainerEncoder.blobRef(for: uiConfigAppBlob)
        blobs[uiConfigAppRef] = uiConfigAppBlob

        let uiConfigLocalizationsBlob = builder.uiConfigLocalizationsBlobData()
        let uiConfigLocalizationsRef = RCContainerEncoder.blobRef(for: uiConfigLocalizationsBlob)
        blobs[uiConfigLocalizationsRef] = uiConfigLocalizationsBlob

        let configJSON = builder.configJSONData(
            manifest: self.configManifest,
            workflowRefsById: workflowRefs,
            uiConfigAppRef: uiConfigAppRef,
            uiConfigLocalizationsRef: uiConfigLocalizationsRef
        )
        self.configContainerData = RCContainerEncoder.container(config: configJSON, contentElements: [])
        self.blobsByRef = blobs
    }

    func blobData(forRef ref: String) -> Data? {
        return self.blobsByRef[ref]
    }

    var allBlobRefs: [String] {
        return Array(self.blobsByRef.keys)
    }

}

/// Raw JSON dictionary builders, kept separate so `BenchmarkPayloadFactory.init` reads as the
/// wiring of refs into the config payload.
private struct PayloadBuilder {

    let paywallCount: Int
    let workflowCount: Int

    static func productIdentifier(index: Int) -> String {
        return "com.revenuecat.benchmark.product_\(index)"
    }

    func offeringsData() -> Data {
        return self.data([
            "current_offering_id": "offering_0",
            "offerings": (0..<self.paywallCount).map { self.offering(index: $0) },
            "placements": [
                "fallback_offering_id": "offering_0",
                "offering_ids_by_placement": [:]
            ]
        ])
    }

    func workflowBlobData(index: Int) -> Data {
        return self.data([
            "id": "workflow_\(index)",
            "display_name": "Benchmark Workflow \(index)",
            "initial_step_id": "step-1",
            "single_step_fallback_id": "step-1",
            "steps": [
                "step-1": [
                    "id": "step-1",
                    "type": "paywall",
                    "screen_id": "screen-1"
                ]
            ],
            "screens": [:],
            "metadata": [
                "benchmark_index": index,
                "benchmark_payload": String(repeating: "w", count: 256)
            ]
        ])
    }

    func uiConfigAppBlobData() -> Data {
        return self.data([
            "colors": [:],
            "fonts": [:]
        ])
    }

    func uiConfigLocalizationsBlobData() -> Data {
        return self.data([
            "en_US": [
                "benchmark.title": "Benchmark title",
                "benchmark.subtitle": "Benchmark subtitle"
            ]
        ])
    }

    func configJSONData(
        manifest: String,
        workflowRefsById: [String: String],
        uiConfigAppRef: String,
        uiConfigLocalizationsRef: String
    ) -> Data {
        var workflowsTopic: [String: Any] = [:]
        for (workflowId, ref) in workflowRefsById {
            let index = Int(workflowId.split(separator: "_").last.map(String.init) ?? "0") ?? 0
            workflowsTopic[workflowId] = [
                "offering_identifier": "offering_\(self.paywallCount == 0 ? 0 : index % self.paywallCount)",
                "blob_ref": ref,
                "prefetch": true
            ]
        }

        // Only workflow blobs are prefetched: those are what offerings delivery awaits
        // (`awaitTopicAndPrefetchBlobsReady(.workflows)`). Prefetching ui_config blobs too
        // would leave downloads running past the measured completion, corrupting the
        // per-iteration request/byte accounting; they stay fetchable on demand via blob_ref.
        // Sorted so the payload bytes are stable across processes (JSON arrays keep their order).
        let prefetchBlobs = workflowRefsById.values.sorted()

        return self.data([
            "domain": "app",
            "manifest": manifest,
            "active_topics": ["sources", "workflows", "ui_config"],
            "prefetch_blobs": prefetchBlobs,
            "topics": [
                "sources": [
                    "api": [
                        "sources": [
                            ["url": "https://api.revenuecat.com/", "priority": 0, "weight": 100]
                        ]
                    ],
                    "blob": [
                        "sources": [
                            ["url_format": BenchmarkPayloadFactory.blobURLFormat, "priority": 0, "weight": 100]
                        ]
                    ]
                ],
                "workflows": workflowsTopic,
                "ui_config": [
                    "app": ["blob_ref": uiConfigAppRef],
                    "localizations": ["blob_ref": uiConfigLocalizationsRef]
                ]
            ]
        ])
    }

}

private extension PayloadBuilder {

    func offering(index: Int) -> [String: Any] {
        let offeringIdentifier = "offering_\(index)"
        return [
            "identifier": offeringIdentifier,
            "description": "Benchmark offering \(index)",
            "packages": [
                [
                    "identifier": "$rc_monthly",
                    "platform_product_identifier": Self.productIdentifier(index: index)
                ]
            ],
            "metadata": [
                "benchmark_index": index,
                "benchmark_payload": String(repeating: "m", count: 64)
            ],
            "paywall_components": self.paywallComponents(id: "paywall_\(index)", offeringIdentifier: offeringIdentifier)
        ]
    }

    func paywallComponents(id: String, offeringIdentifier: String) -> [String: Any] {
        return [
            "id": id,
            "default_locale": "en_US",
            "revision": 1,
            "template_name": "benchmark_components",
            "asset_base_url": "https://assets.revenuecat.com",
            "components_localizations": [
                "en_US": [
                    "title": "Benchmark title for \(offeringIdentifier)",
                    "cta": "Continue"
                ]
            ],
            "components_config": [
                "base": [
                    "stack": self.paywallStack(),
                    "background": [
                        "type": "color",
                        "value": [
                            "light": ["type": "hex", "value": "#FFFFFF"]
                        ]
                    ]
                ]
            ]
        ]
    }

    func paywallStack() -> [String: Any] {
        return [
            "type": "stack",
            "components": [self.paywallTitleComponent()],
            "dimension": [
                "type": "vertical",
                "alignment": "center",
                "distribution": "center"
            ],
            "size": [
                "width": ["type": "fill"],
                "height": ["type": "fill"]
            ],
            "padding": ["top": 0, "bottom": 0, "leading": 0, "trailing": 0],
            "margin": ["top": 0, "bottom": 0, "leading": 0, "trailing": 0],
            "spacing": 16
        ]
    }

    func paywallTitleComponent() -> [String: Any] {
        return [
            "type": "text",
            "text_lid": "title",
            "font_weight": "bold",
            "font_size": 24,
            "color": [
                "light": ["type": "hex", "value": "#111111"]
            ],
            "size": [
                "width": ["type": "fill"],
                "height": ["type": "fit"]
            ],
            "padding": ["top": 0, "bottom": 0, "leading": 0, "trailing": 0],
            "margin": ["top": 0, "bottom": 0, "leading": 0, "trailing": 0],
            "horizontal_alignment": "center"
        ]
    }

    func data(_ object: Any) -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        } catch {
            preconditionFailure("Invalid benchmark JSON fixture: \(error)")
        }
    }

}
