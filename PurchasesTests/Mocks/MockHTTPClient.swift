import Purchases

class MockHTTPClient: RCHTTPClient {

    var invokedPerformRequest = false
    var invokedPerformRequestCount = 0
    var shouldInvokeCompletion = true

    var stubbedCompletionStatusCode = 200
    var stubbedCompletionResponse: [AnyHashable: Any]? = [:]
    var stubbedCompletionError: Error? = nil

    var invokedPerformRequestParameters: (HTTPMethod: String,
                                          path: String,
                                          requestBody: [AnyHashable: Any]?,
                                          headers: [String: String]?,
                                          completionHandler: RCHTTPClientResponseHandler?)?
    var invokedPerformRequestParametersList = [
        (HTTPMethod: String,
            path: String,
            requestBody: [AnyHashable: Any]?,
            headers: [String: String]?,
            completionHandler: RCHTTPClientResponseHandler?)]()

    override func performRequest(_ HTTPMethod: String, path: String, body requestBody: [AnyHashable: Any]?,
                                 headers: [String: String]?,
                                 completionHandler: RCHTTPClientResponseHandler?) {
        invokedPerformRequest = true
        invokedPerformRequestCount += 1
        invokedPerformRequestParameters = (HTTPMethod, path, requestBody, headers, completionHandler)
        invokedPerformRequestParametersList.append((HTTPMethod, path, requestBody, headers, completionHandler))
        if (shouldInvokeCompletion) {
            completionHandler?(stubbedCompletionStatusCode,
                               stubbedCompletionResponse,
                               stubbedCompletionError)
        }
    }
}