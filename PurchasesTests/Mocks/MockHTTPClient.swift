@testable import RevenueCat

class MockHTTPClient: HTTPClient {

    struct InvokedPerformRequestParameters {
        let request: HTTPRequest
        let headers: [String: String]?
        let completionHandler: HTTPClient.Completion?
    }

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
