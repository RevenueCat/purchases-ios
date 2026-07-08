import XCTest

@_spi(Internal) @testable import SDKConfigBenchmarkCore

final class BenchmarkPayloadFactoryTests: BenchmarkTestCase {

    private let factory = BenchmarkPayloadFactory(paywallCount: 5, workflowCount: 7)

    func testOfferingsDataDecodesIntoSDKModel() throws {
        let response = try JSONDecoder.default.decode(OfferingsResponse.self, from: self.factory.offeringsData)

        XCTAssertEqual(response.offerings.count, 5)
        XCTAssertEqual(response.currentOfferingId, "offering_0")
        XCTAssertEqual(response.productIdentifiers.count, 5)

        for offering in response.offerings {
            let components = try XCTUnwrap(offering.paywallComponents)
            XCTAssertNil(components.errorInfo, "paywall components must decode without collected errors")
            XCTAssertEqual(components.componentsConfig.base.stack.components.count, 1)
        }
    }

    func testConfigContainerDecodesIntoRemoteConfiguration() throws {
        let container = try RemoteConfigContainer(data: self.factory.configContainerData)
        let configData = try container.configElement.withDecodedPayloadBytes { Data($0) }
        let configuration = try JSONDecoder.default.decode(RemoteConfiguration.self, from: configData)

        XCTAssertEqual(configuration.domain, "app")
        XCTAssertEqual(configuration.manifest, self.factory.configManifest)
        XCTAssertEqual(Set(configuration.activeTopics), ["sources", "workflows", "ui_config"])

        let workflowsTopic = try XCTUnwrap(configuration.topics.entries["workflows"])
        XCTAssertEqual(workflowsTopic.count, 7)
        for item in workflowsTopic.values {
            XCTAssertTrue(item.prefetch)
            XCTAssertNotNil(item.blobRef)
        }

        let sourcesTopic = try XCTUnwrap(configuration.topics.entries["sources"])
        XCTAssertNotNil(sourcesTopic["api"])
        XCTAssertNotNil(sourcesTopic["blob"])
    }

    func testAllReferencedBlobsResolveAndValidate() throws {
        let container = try RemoteConfigContainer(data: self.factory.configContainerData)
        let configData = try container.configElement.withDecodedPayloadBytes { Data($0) }
        let configuration = try JSONDecoder.default.decode(RemoteConfiguration.self, from: configData)

        let referencedRefs = Set(configuration.prefetchBlobs)
        XCTAssertEqual(referencedRefs.count, 7 + 2)

        for ref in referencedRefs {
            let blob = try XCTUnwrap(self.factory.blobData(forRef: ref), "missing blob for ref \(ref)")
            XCTAssertEqual(RCContainerEncoder.blobRef(for: blob), ref, "blob refs must be content-addressed")
        }
    }

    func testWorkflowBlobDecodesIntoPublishedWorkflow() throws {
        let container = try RemoteConfigContainer(data: self.factory.configContainerData)
        let configData = try container.configElement.withDecodedPayloadBytes { Data($0) }
        let configuration = try JSONDecoder.default.decode(RemoteConfiguration.self, from: configData)

        let workflowsTopic = try XCTUnwrap(configuration.topics.entries["workflows"])
        let ref = try XCTUnwrap(workflowsTopic.values.first?.blobRef)
        let blob = try XCTUnwrap(self.factory.blobData(forRef: ref))

        let workflow = try JSONDecoder.default.decode(PublishedWorkflow.self, from: blob)
        XCTAssertEqual(workflow.initialStepId, "step-1")
    }

    func testPayloadsAreDeterministic() {
        let other = BenchmarkPayloadFactory(paywallCount: 5, workflowCount: 7)

        XCTAssertEqual(other.offeringsData, self.factory.offeringsData)
        XCTAssertEqual(other.configContainerData, self.factory.configContainerData)
        XCTAssertEqual(Set(other.allBlobRefs), Set(self.factory.allBlobRefs))
    }

}
