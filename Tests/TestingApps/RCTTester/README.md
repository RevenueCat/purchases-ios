# RCTTester

RCTTester (RevenueCat Transactions Tester) is an internal testing app designed to manually verify the accuracy of attribution data sent in `POST /receipt` requests by the RevenueCat SDK across all supported purchase scenarios.

## Purpose

The SDK sends various attribution metadata with receipt posts to help track the origin of purchases. This app allows testing that the correct data is sent in different scenarios:

- **Offering context**: Which offering/placement the purchase originated from
- **Paywall attribution**: Which paywall was displayed when the purchase was made
- **SDK originated**: Whether the purchase was initiated through SDK methods or detected externally
- **Initiation source**: Whether the transaction came from `.purchase`, `.restore`, or `.queue`
- **Observer mode state**: The `purchasesAreCompletedBy` setting at purchase time

## Setup

1. Generate and open the project:
   ```bash
   tuist generate RCTTester
   ```

2. Select the **RCTTester** scheme and run on a simulator or device.

3. On first launch, enter your RevenueCat API key in the app (or set it via `Local.xcconfig`).
