# Contributing
___

### You can do this!
We've tagged a number of issues as [you can do this!](https://github.com/RevenueCat/purchases-ios/labels/you%20can%20do%20this%21). These will generally not require much (or any!) working knowledge of our SDK, they are tasks like migrating a single `enum` into Swift, or a uncomplicated `model` from objc to swift.

If you decide you want to help, that [you can do this!](https://github.com/RevenueCat/purchases-ios/labels/you%20can%20do%20this%21) tag is a good place to start. Now, here's how you can actually get going:

- Follow the directions from [2. Create a fork/branch.](#2-create-a-forkbranch) to setup your environment.
- Find an issue that speaks to you, and comment in it "I've got this" or something like that 😄.
- If the issue isn't clear enough, feel free to tag in sdk team `@RevenueCat/sdk` asking for clarification.
- Work on the issue! 
- Use our [Swift Style Guide](./SwiftStyleGuide.swift) to ensure that the style is consistent with the rest of the codebase.
- Once you think you're done, build the `APITester` target. That target compiles a file that contains references to all public api for the `Purchases` framework. This is how we ensure our changes don't impact the public api.
- If that builds, then follow [the final steps (Create a pull request to RevenueCat/main)](#7-create-a-pull-request-to-revenuecatmain-and-request-review)
- Done!

___
## Contributing to the main project


#### 1. Create an issue to make sure its something that should be done.

Before submitting a Github issue, please make sure to

- Search for [existing Github issues](https://github.com/RevenueCat/purchases-ios/issues)
- Review our [Help Center](https://support.revenuecat.com/hc/en-us)
- Read our [docs.revenuecat.com](https://docs.revenuecat.com/)

## Common project specific issues.

There are certain project specific issues that are commonly misinterpreted as bugs.

- [Offerings, products, or available packages are empty](https://support.revenuecat.com/hc/en-us/articles/360041793174)
- [Invalid Play Store credentials errors](https://support.revenuecat.com/hc/en-us/articles/360046398913)
- [Unable to connect to the App Store (STORE_PROBLEM) errors](https://support.revenuecat.com/hc/en-us/articles/360046399333)

For support I'd recommend our [online community](https://community.revenuecat.com), [StackOverflow](https://stackoverflow.com/tags/revenuecat/) and/or [Help Center](https://support.revenuecat.com/hc/en-us) 👍

If you have a clearly defined bug (with a [Minimal, Complete, and Reproducible example](https://stackoverflow.com/help/minimal-reproducible-example)) that is not specific to your project, follow the steps in the GitHub Issue template to file it with RevenueCat without removing any of the steps. For SDK-related bugs, make sure they can be reproduced on a physical device, not a simulator (there are simulator-specific problems that prevent purchases from working).

#### 2. Create a fork/branch.

#### 3. Setup your development environment.

##### Install fastlane.

We use fastlane 🚀 for all our automation, including setting up out dev environment.

```bash
$brew install fastlane
```

##### Run the setup lane.

```bash
$fastlane setup_dev
```

This installs [Homebrew](https://brew.sh/), and then [SwiftLint](https://github.com/realm/SwiftLint). After, it links in our pre-commit hook to run swiftlint. That saves you time so you don't have to wait for our CI to do it ⏱.

#### 4. Check out the Style Guide.
The [Swift Style Guide](./SwiftStyleGuide.swift) illustrates the code style used across the project!

#### 5. Build something!

Use our [Swift Style Guide](./SwiftStyleGuide.swift) to ensure that the style is consistent with the rest of the codebase. This is pretty subjective, so don't get too stressed about it. If there's any issue, we'll suggest a change.

#### 6. Write tests for your fix/new functionality.

You can run the tests by selecting the All Tests Scheme in Xcode and hitting `Cmd+U`.
The tests are written in Swift, using XCTest and [Nimble](https://github.com/quick/nimble).

#### 7. Create a pull request to RevenueCat/main and request review.

Explain in your pull request the work that was done and the reasoning.

#### 8. Make changes in response to review.

#### 9. Bask in the glory of community maintained software 😎
