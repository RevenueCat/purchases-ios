- Seventh beta for RevenueCat framework 🎉
    100% Swift framework + ObjC support.
- See our [RevenueCat V4 API update doc](docs/V4_API_Updates.md) for API updates.
- macOS: improved ErrorCode.storeProblemError to indicate potential cancellation
    https://github.com/RevenueCat/purchases-ios/pull/943
- Log when duplicate subscription time lengths exist during Offering init
    https://github.com/RevenueCat/purchases-ios/pull/954
- PurchasesOrchestrator.paymentDiscount(forProductDiscount:product:completion:): improved error information
    https://github.com/RevenueCat/purchases-ios/pull/957
- Make a public originalData a thing for all our datatypes
    https://github.com/RevenueCat/purchases-ios/pull/956
- Detect ErrorCode.productAlreadyPurchasedError when SKError.unknown is actually cased by it
    https://github.com/RevenueCat/purchases-ios/pull/965
