fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios setup_dev
```
fastlane ios setup_dev
```
Setup development environment
### ios test
```
fastlane ios test
```
Runs all the tests
### ios bump
```
fastlane ios bump
```
Increment build number
### ios bump_and_update_changelog
```
fastlane ios bump_and_update_changelog
```
Increment build number and update changelog
### ios github_release
```
fastlane ios github_release
```
Make github release
### ios create_sandbox_account
```
fastlane ios create_sandbox_account
```
Create sandbox account
### ios deployment_checks
```
fastlane ios deployment_checks
```
Deployment checks
### ios build_tv_watch_mac
```
fastlane ios build_tv_watch_mac
```
tvOS, watchOS, and macOS build
### ios carthage_archive
```
fastlane ios carthage_archive
```
Run the carthage archive steps to prepare for carthage distribution
### ios archive
```
fastlane ios archive
```
archive
### ios replace_api_key_integration_tests
```
fastlane ios replace_api_key_integration_tests
```
replace API KEY for integration tests
### ios deploy
```
fastlane ios deploy
```
Deploy
### ios prepare_next_version
```
fastlane ios prepare_next_version
```
Prepare next version
### ios export_xcframework
```
fastlane ios export_xcframework
```
Export XCFramework
### ios storekit_tests
```
fastlane ios storekit_tests
```
Run StoreKitTests

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
