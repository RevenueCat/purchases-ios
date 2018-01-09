# Restoring Purchases

A common cause for app rejection is not properly giving users the ability to restore their purchases. Apple explains a couple of different ways to do this in [their documentation](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/Restoring.html). 

The important sentence is: 

*"Include some mechanism in your app to let the user restore their purchases, such as a Restore Purchases button".*

As long as a user has some way to restore there previous purchases, you are good. The two main ways of achieving this are:

1. If your app has accounts: associating all purchases with an account and letting users login to restore their purchases.
2. If your app does not have accounts: restoring purchases by re-sending the transactions or receipt.

For option one, RevenueCat handles all of it for you. If users in your app can only make purchases while logged in, then you just make sure to sync the latest expiration from RevenueCat when they login and that you use an RevenueCat `appUserID` that is related to their account.

For option two, if users can make a purchase without having an account, you will need to provide a method of restoring from the App Store account.

## Purchases Without Accounts

For apps where subscriptions can be purchased outside of a logged in account, you need to provide your users a way to restore purchases directly. You should add a button to your purchase flow or your settings to allow users to trigger this.

To restore purchases with RevenueCat, you should call the follow:
```
self.purchases.restoreTransactionsForAppStoreAccount();
```

Any other users using the current App Store account for their subscriptions will lose their subscriptions. This is the desired behavior to keep users from sharing App Store accounts to share subscriptions.

Make sure you also implement the restoration related optional delegate methods:

```
- (void)purchases:(RCPurchases *)purchases restoredTransactionsWithPurchaserInfo:(RCPurchaserInfo *)purchaserInfo;
- (void)purchases:(RCPurchases *)purchases failedToRestoreTransactionsWithReason:(NSError *)failureReason;
```