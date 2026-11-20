#### Releasing:
1. Create a `fastlane/.env` file with your GitHub API token (see `fastlane/.env.SAMPLE`). This will be used to create the PR, so you should use your own token so the PR gets assigned to you.
2. Run `bundle exec fastlane ios bump`
    1. Confirm base branch is correct
    2. Input new version number
    3. Update CHANGELOG.latest.md to include the latest changes. Call out API changes (if any). You can use the existing CHANGELOG.md as a base for formatting. To compile the changelog, you can compare the changes between the base branch for the release (usually main) against the latest release, by checking https://github.com/revenuecat/purchases-ios/compare/<latest_release>...<base_branch>. For example, https://github.com/revenuecat/purchases-ios/compare/4.1.0...main.
    4. A new branch and PR will automatically be created
3. When the PR is approved, the `wait-for-pr-approval` job in CircleCI is approved automatically, and CircleCI tags the version once the release branch tests pass. If that does not happen, approve the job in CircleCI by hand, or tag the last commit in the release branch and push the tag.
4. The rest will be performed automatically by CircleCI. If the automation fails, you can revert to manually calling `bundle exec fastlane deploy`.
5. The release branch PR can be merged after the release is completed.

##### Hotfixes:
To release a fix merged into `main` without releasing the rest of `main`, for example 3.9.1 when the latest is 4.0.0, or 4.0.1 while `main` is not ready to release:
1. Comment `@RCGitBot hotfix 3` on the merged fix PR. The bot cherry-picks the fix onto the latest 3.x tag, bumps the version, opens a `release/3.9.1` PR into a new `hotfix/3.9.0` branch and comments the release PR link on the fix PR.
1. Approve the release PR, but **don't merge it**. Once tests pass, CircleCI tags 3.9.1, deploys it and merges the PR into `hotfix/3.9.0`. If that does not happen, approve the `wait-for-pr-approval` job in CircleCI by hand, or tag the last commit of `release/3.9.1` with `3.9.1` and push the tag.
1. Delete the `hotfix/3.9.0` branch and add the release to CHANGELOG.md on `main`.

If the cherry-pick conflicts, the bot comments a local command instead: run it from `main`, resolve the conflicts, run `git cherry-pick --continue`, then run it again to open the PR.

To patch an older minor (3.8.x while 3.9.0 exists), run `bundle exec fastlane ios hotfix pr:<number> version:3.8.2` locally (releases 3.8.3). Both local commands need `fastlane/.env`, like `bump`.
