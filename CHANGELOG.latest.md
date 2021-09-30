- Updates `offeringsWithCompletionBlock:` to fix a case where if the backend response was erroneous, the completion block would not be called. 
- Also updates `offeringsWithCompletionBlock:` so that if there are no offerings in the RevenueCat dashboard, or no `SKProduct`s could be fetched with the product identifiers registered in the RevenueCat dashboard, the method returns an error with instructions on how to fix the issues.
    https://github.com/revenuecat/purchases-ios/pulls/885
