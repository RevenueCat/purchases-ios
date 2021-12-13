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
### ios replace_version_number
```
fastlane ios replace_version_number
```
Replace version number in project and supporting files
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
### ios release_checks
```
fastlane ios release_checks
```
Release checks
### ios build_tv_watch_mac
```
fastlane ios build_tv_watch_mac
```
build tvOS, watchOS, macOS
### ios build_mac
```
fastlane ios build_mac
```
macOS build
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
### ios build_swift_api_tester
```
fastlane ios build_swift_api_tester
```
build Swift API tester
### ios build_objc_api_tester
```
fastlane ios build_objc_api_tester
```
build ObjC API tester
### ios replace_api_key_integration_tests
```
fastlane ios replace_api_key_integration_tests
```
replace API KEY for integration tests
### ios release
```
fastlane ios release
```
Release to CocoaPods, create Carthage archive, export XCFramework, and create GitHub release
### ios bump
```
fastlane ios bump
```
Bump version, edit changelog, and create pull request
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
### ios backend_integration_tests
```
fastlane ios backend_integration_tests
```
Run BackendIntegrationTests
### ios update_swift_package_commit
```
fastlane ios update_swift_package_commit
```
Update swift package commit
### ios generate_docs
```
fastlane ios generate_docs
```
Generate Jazzy Docs

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
