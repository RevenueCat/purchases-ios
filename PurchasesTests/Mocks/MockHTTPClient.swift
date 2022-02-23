@testable import RevenueCat

class MockHTTPClient: HTTPClient {

    struct InvokedPerformRequestParameters {
        let httpMethod: String
        let path: String
        let requestBody: [String: Any]?
        let headers: [String: String]?
        let completionHandler: ((Int, [String: Any]?, Error?) -> Void)?
    }

    var invokedPerformRequest = false
    var invokedPerformRequestCount = 0
    var shouldInvokeCompletion = true

    var stubbedCompletionStatusCode = 200
    var stubbedCompletionResponse: [String: Any]? = [:]
    var stubbedCompletionError: Error?

    var invokedPerformRequestParameters: InvokedPerformRequestParameters?
    var invokedPerformRequestParametersList = [InvokedPerformRequestParameters]()

    override func performGETRequest(path: String,
                                    headers authHeaders: [String: String],
                                    completionHandler: ((Int, [String: Any]?, Error?) -> Void)?) {
        performRequest("GET",
                       path: path,
                       requestBody: nil,
                       headers: authHeaders,
                       completionHandler: completionHandler)
    }

    override func performPOSTRequest(path: String,
                                     requestBody: [String: Any],
                                     headers authHeaders: [String: String],
                                     completionHandler: ((Int, [String: Any]?, Error?) -> Void)?) {
        performRequest("POST",
                       path: path,
                       requestBody: requestBody,
                       headers: authHeaders,
                       completionHandler: completionHandler)
    }
}

private extension MockHTTPClient {
    func performRequest(_ httpMethod: String,
                        path: String,
                        requestBody: [String: Any]?,
                        headers: [String: String]?,
                        completionHandler: ((Int, [String: Any]?, Error?) -> Void)?) {
        invokedPerformRequest = true
        invokedPerformRequestCount += 1
        let parameters = InvokedPerformRequestParameters(
            httpMethod: httpMethod,
            path: path,
            requestBody: requestBody,
            headers: headers,
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
