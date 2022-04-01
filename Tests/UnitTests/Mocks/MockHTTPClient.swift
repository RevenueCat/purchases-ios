@testable import RevenueCat

import Nimble
import SnapshotTesting
import XCTest

class MockHTTPClient: HTTPClient {

    struct Call {

        let request: HTTPRequest
        let headers: RequestHeaders

    }

    struct Response {

        let response: Result<HTTPResponse, Error>

        private init(response: Result<HTTPResponse, Error>) {
            self.response = response
        }

        init(statusCode: HTTPStatusCode, response: [String: Any] = [:]) {
            self.init(response: .success(.init(statusCode: statusCode, jsonObject: response)))
        }

        init(error: Error) {
            self.init(response: .failure(error))
        }

    }

    var mocks: [HTTPRequest.Path: Response] = [:]
    var calls: [Call] = []

    init(
        systemInfo: SystemInfo,
        eTagManager: ETagManager,
        dnsChecker: DNSCheckerType.Type = DNSChecker.self,
        sourceTestFile: StaticString = #file
    ) {
        self.sourceTestFile = sourceTestFile

        super.init(systemInfo: systemInfo,
                   eTagManager: eTagManager,
                   dnsChecker: dnsChecker)
    }

    private let sourceTestFile: StaticString

    override func perform(_ request: HTTPRequest,
                          authHeaders: RequestHeaders,
                          completionHandler: Completion?) {
        let call = Call(request: request, headers: authHeaders)

        DispatchQueue.main.async {
            self.calls.append(call)

            assertSnapshot(matching: call,
                           as: .formattedJson,
                           file: self.sourceTestFile,
                           testName: CurrentTestCaseTracker.sanitizedTestName)

            let response = self.mocks[request.path]

            completionHandler?(response?.response ?? .success(.init(statusCode: .success, jsonObject: [:])))
        }
    }

    func mock(requestPath: HTTPRequest.Path, response: Response) {
        self.mocks[requestPath] = response
    }

}

// MARK: - MockHTTPClient.Call Encodable

extension HTTPRequest: Encodable {

    enum CodingKeys: String, CodingKey {

        case method
        case body
        case url

    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.path.url, forKey: .url)
        try container.encode(self.method.httpMethod, forKey: .method)

        if let body = self.requestBody {
            try body.encode(inContainer: &container, forKey: .body)
        } else {
            try container.encodeNil(forKey: .body)
        }
    }

}

extension MockHTTPClient.Call: Encodable { }

// MARK: -

private extension Encodable {
    func encode<Container: KeyedEncodingContainerProtocol>(
        inContainer container: inout Container,
        forKey key: Container.Key
    ) throws {
        try container.encode(self, forKey: key)
    }
}
