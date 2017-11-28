# Managing Purchases Lifecycle

It is important to consider the lifecyle of the `RCPurchases` instance and your delegate. `RCPurchases` is initialized with an identifier specific to the user for a specific reason. `RCPurchases` only knows how to handle subscription renewals, and purchases, if there is a well defined user. If there is no user, there is no clearly correct behavior for `RCPurchases`. Here are a few tips for how and when to instantiate `RCPurchases`:

1. Instantiate `RCPurchases` as soon as you have a user id, this can be when a user logs in or creates an account, or when your app is launched if you don't have your own backend.

2. Be sure to release any references to `RCPurchases` when a user logs out to ensure that subsequent purchases aren't sent to the logged out user. This is important to ensure correct behavior when switching accounts.

3. Always remember to create a new `RCPurchases` when a new account logs in, even if another account was logged in previously.

