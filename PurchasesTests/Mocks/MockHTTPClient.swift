@testable import RevenueCat

import Nimble
import SnapshotTesting
import XCTest

class MockHTTPClient: HTTPClient {

    struct Call {

        let request: HTTPRequest
        let headers: [String: String]

    }

    struct Response {

        let statusCode: HTTPStatusCode
        let response: [String: Any]?
        let error: Error?

        init(statusCode: HTTPStatusCode, response: [String: Any]?, error: Error? = nil) {
            self.statusCode = statusCode
            self.response = response
            self.error = error
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
                          authHeaders: [String: String],
                          completionHandler: Completion?) {
        DispatchQueue.main.async {
            self.calls.append(Call(request: request, headers: authHeaders))

            if let body = request.requestBody {
                assertSnapshot(matching: body, as: .formattedJson,
                               file: self.sourceTestFile,
                               testName: CurrentTestCaseTracker.sanitizedTestName)
            }

            let response = self.mocks[request.path]

            completionHandler?(response?.statusCode ?? .success,
                               response?.response ?? [:],
                               response?.error)
        }
    }

    func mock(requestPath: HTTPRequest.Path, response: Response) {
        self.mocks[requestPath] = response
    }

}

extension MockHTTPClient.Call {

    // fixme: use SnapshotTesting to compare the whole `HTTPRequest` instead of only `requestBody`.
    func expectToEqual(_ other: MockHTTPClient.Call, file: FileString = #file, line: UInt = #line) throws {

        // Body comparison is done by SnapshotTesting
        if other.request.requestBody == nil {
            expect(file: file, line: line, self.request.requestBody).to(beNil())
        } else {
            expect(file: file, line: line, self.request.requestBody).toNot(beNil())
        }

        expect(file: file, line: line, self.request.path) == other.request.path
        expect(file: file, line: line, self.request.methodType) == other.request.methodType
        expect(file: file, line: line, self.headers) == other.headers
    }

}

extension HTTPRequest {

    enum MethodType {
        case get
        case post
    }

    /// For testing purposes only
    var methodType: MethodType {
        switch self.method {
        case .get: return .get
        case .post: return .post
        }
    }

}
