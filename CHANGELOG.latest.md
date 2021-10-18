- Adds a timeout when `SKProductsRequest` hangs forever, which may happen with some sandbox accounts. 
When this happens, the SDK will return an error and post a warning to the logs.
    https://github.com/RevenueCat/purchases-ios/pull/910
