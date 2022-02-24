RevenueCat iOS SDK v4 is here!! 

![Dancing cats](https://media.giphy.com/media/lkbNG2zqzHZUA/giphy.gif)

[Full Changelog](https://github.com/revenuecat/purchases-ios/compare/4.0.0...3.14.1)

### Migration Guide
- See our [RevenueCat V4 API update doc](Documentation.docc/V4_API_Migration_guide.md) for API updates.
**Note:** This release is based off of 4.0.0-rc.4. Developers migrating from that version shouldn't see any changes. 

### API changes:
There have been a lot of changes since v3! 

Here are the highlights:

##### Async / Await alternative APIs
New `async / await` alternatives for all APIs that have completion blocks, as well as an `AsyncStream` for CustomerInfo. 

##### New types and cleaned up naming
New types that wrap StoreKit's native types, and we cleaned up the naming of other types and methods for a more consistent experience. 

##### New APIs for Customer Support
You can now use `showManageSubscriptions()` and `beginRefundRequest()` to help your users manage their subscriptions right from the app.

##### Rewritten in Swift 
We [rewrote the SDK in 100% Swift](https://www.revenuecat.com/blog/migrating-our-objective-c-sdk-to-swift). This made the code more uniform and easy to maintain, and helps us better support StoreKit 2. 

##### StoreKit 2 Support [Beta]
**[Experimental]** Introduced support for using StoreKit 2 under the hood for compatible devices. This is currently in beta phase, and disabled by default. 
When enabled, StoreKit 2 APIs will be used under the hood for purchases in compatible devices. You can enable this by configuring the SDK passing `useStoreKit2IfAvailable: true`. 
On devices that don't support StoreKit 2, StoreKit 1 will be used automatically instead. 
 
##### Full API changes list
- See our [RevenueCat V4 API update doc](Documentation.docc/V4_API_Migration_guide.md) for API updates.

### Documentation: 

We built a new Documentation site with Docc with cleaner and more detailed docs. 
The new documentation can be found in https://revenuecat-docs.netlify.app/documentation/Revenuecat. 