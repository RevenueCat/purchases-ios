@testable import RevenueCat

import SnapshotTesting
import XCTest

class MockHTTPClient: HTTPClient {

    struct InvokedPerformRequestParameters {
        let request: HTTPRequest
        let headers: [String: String]?
        let completionHandler: HTTPClient.Completion?
    }

    init(
        systemInfo: SystemInfo,
        eTagManager: ETagManager,
        dnsChecker: DNSCheckerType.Type = DNSChecker.self,
        sourceTest: StaticString = #file
    ) {
        self.sourceTest = sourceTest

        super.init(systemInfo: systemInfo,
                   eTagManager: eTagManager,
                   dnsChecker: dnsChecker)
    }

    private let sourceTest: StaticString

    var invokedPerformRequest = false
    var invokedPerformRequestCount = 0
    var shouldInvokeCompletion = true

    var stubbedCompletionStatusCode: HTTPStatusCode = .success
    var stubbedCompletionResponse: [String: Any]? = [:]
    var stubbedCompletionError: Error?

    var invokedPerformRequestParameters: InvokedPerformRequestParameters?
    var invokedPerformRequestParametersList = [InvokedPerformRequestParameters]()

    override func perform(_ request: HTTPRequest,
                          authHeaders: [String: String],
                          completionHandler: Completion?) {
        DispatchQueue.main.async { [self] in
            if let body = request.requestBody {
                assertSnapshot(matching: body, as: .formattedJson,
                               file: self.sourceTest,
                               testName: CurrentTestCaseTracker.sanitizedTestName)
            }

            invokedPerformRequest = true
            invokedPerformRequestCount += 1
            let parameters = InvokedPerformRequestParameters(
                request: request,
                headers: authHeaders,
                completionHandler: completionHandler
            )
            invokedPerformRequestParameters = parameters
            invokedPerformRequestParametersList.append(parameters)
            if shouldInvokeCompletion {
                completionHandler?(stubbedCompletionStatusCode,
                                   stubbedCompletionResponse,
                                   stubbedCompletionError)
            }
        }
    }
}
