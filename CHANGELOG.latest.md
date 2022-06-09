_This release is compatible with Xcode 14 beta 1_

### New Features

* `EntitlementInfos`: added `activeInAnyEnvironment` and `activeInCurrentEnvironment` (#1647) via NachoSoto (@NachoSoto)

In addition to `EntitlementInfos.active`, two new methods are added to allow detecting entitlements from sandbox and production environments:
```swift
customerInfo.entitlements.activeInCurrentEnvironment
customerInfo.entitlements.activeInAnyEnvironment
```

### Bug fixes

* `MacDevice`: changed usage of `kIOMasterPortDefault` to fix Catalyst compilation on Xcode 14 (#1676) via NachoSoto (@NachoSoto)
* `Result.init(value:error:)`: avoid creating error if value is provided (#1672) via NachoSoto (@NachoSoto)
