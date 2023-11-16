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

        let response: VerifiedHTTPResponse<Data>.Result
        let delay: DispatchTimeInterval

        private init(response: VerifiedHTTPResponse<Data>.Result, delay: DispatchTimeInterval) {
            self.response = response
            self.delay = delay
        }

        init(
            statusCode: HTTPStatusCode,
            response: [String: Any] = [:],
            responseHeaders: HTTPResponse.Headers = [:],
            verificationResult: VerificationResult = .defaultValue,
            delay: DispatchTimeInterval = .never
        ) {
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: response)

            let response = VerifiedHTTPResponse(
                response: .init(
                    httpStatusCode: statusCode,
                    responseHeaders: responseHeaders,
                    body: data
                ),
                verificationResult: verificationResult
            )

            self.init(response: .success(response), delay: delay)
        }

        init(error: NetworkError, delay: DispatchTimeInterval = .never) {
            self.init(response: .failure(error), delay: delay)
        }

    }

    var mocks: [URL: Response] = [:]
    var calls: [Call] = []

    init(apiKey: String,
         systemInfo: SystemInfo,
         eTagManager: ETagManager,
         dnsChecker: DNSCheckerType.Type = DNSChecker.self,
         requestTimeout: TimeInterval = 7,
         sourceTestFile: StaticString = #file) {
        self.sourceTestFile = sourceTestFile

        super.init(apiKey: apiKey,
                   systemInfo: systemInfo,
                   eTagManager: eTagManager,
                   signing: FakeSigning.default,
                   dnsChecker: dnsChecker,
                   requestTimeout: requestTimeout)
    }

    private let sourceTestFile: StaticString

    override func perform<Value: HTTPResponseBody>(
        _ request: HTTPRequest,
        with verificationMode: Signing.ResponseVerificationMode? = nil,
        completionHandler: Completion<Value>?
    ) {
        let verificationMode = verificationMode ?? self.systemInfo.responseVerificationMode

        let request = request
            .requestAddingNonceIfRequired(with: verificationMode)
            .withHardcodedNonce

isRecording = true

        let call = Call(request: request,
                        headers: request.headers(with: self.authHeaders,
                                                 defaultHeaders: self.defaultHeaders,
                                                 verificationMode: verificationMode))

        DispatchQueue.main.async {
            self.calls.append(call)

            assertSnapshot(matching: call,
                           as: .formattedJson,
                           file: self.sourceTestFile,
                           testName: CurrentTestCaseTracker.osVersionAndTestName)

            let mock = self.mocks[request.path.url!] ?? .init(statusCode: .success)

            if let completionHandler = completionHandler {
                let response: VerifiedHTTPResponse<Value>.Result = mock.response.parseResponse()

                if mock.delay != .never {
                    DispatchQueue.main.asyncAfter(deadline: .now() + mock.delay) {
                        completionHandler(response)
                    }
                } else {
                    completionHandler(response)
                }
            }
        }
    }

    func mock(requestPath: HTTPRequest.Path, response: Response) {
        self.mock(path: requestPath, response: response)
    }

    private func mock(path: HTTPRequestPath, response: Response) {
        self.mocks[path.url!] = response
    }

    /// Override headers that depend on the environment to make them stable.
    override var defaultHeaders: RequestHeaders {
        var result = super.defaultHeaders
        result["X-Version"] = "4.0.0"
        // Snapshots are shared across platforms so we need this to be stable.
        result["X-Platform"] = "iOS"
        result["X-Client-Build-Version"] = "12345"
        result["X-Client-Version"] = "17.0.0"
        result["X-Platform-Version"] = "Version 17.0.0 (Build 21A342)"

        if result.keys.contains("X-Apple-Device-Identifier") {
            result["X-Apple-Device-Identifier"] = "5D7C0074-07E4-4564-AAA4-4008D0640881"
        }

        return result
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

private extension HTTPRequest {

    /// Creates a copy of the request replacing the `nonce` with a fixed value
    /// to make snapshot tests deterministic
    var withHardcodedNonce: Self {
        if self.nonce == nil {
            return self
        } else {
            var copy = self
            copy.nonce = "1234567890ab".asData

            return copy
        }
    }

}

private extension Encodable {
    func encode<Container: KeyedEncodingContainerProtocol>(
        inContainer container: inout Container,
        forKey key: Container.Key
    ) throws {
        try container.encode(self, forKey: key)
    }
}
