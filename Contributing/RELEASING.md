#### Releasing:
1. Create a `fastlane/.env` file with your GitHub API token (see `fastlane/.env.SAMPLE`). This will be used to create the PR, so you should use your own token so the PR gets assigned to you. 
2. Run `bundle exec fastlane ios bump`
    1. Input new version number
    2. Update CHANGELOG.latest.md to include the latest changes. Call out API changes (if any). You can use the existing CHANGELOG.md as a base for formatting. To compile the changelog, you can compare the changes between the base branch for the release (usually main) against the latest release, by checking https://github.com/revenuecat/purchases-ios/compare/<latest_release>...<base_branch>. For example, https://github.com/revenuecat/purchases-ios/compare/4.1.0...main. 
    3. A new branch and PR will automatically be created
3. When the PR is approved, approve the hold job created in CircleCI. CircleCI will create a tag for the version. Alternatively, you can tag the last commit in the release branch and push it to the repository.
4. Rhe rest will be performed automatically by CircleCI. If the automation fails, you can revert to manually calling `bundle exec fastlane deploy`.
