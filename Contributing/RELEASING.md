#### Releasing:
1. Create a `fastlane/.env` file with your GitHub API token (see `fastlane/.env.SAMPLE`). This will be used to create the PR, so you should use your own token so the PR gets assigned to you.
2. Run `bundle exec fastlane ios bump`
    1. Confirm base branch is correct
    2. Input new version number
    3. Update CHANGELOG.latest.md to include the latest changes. Call out API changes (if any). You can use the existing CHANGELOG.md as a base for formatting. To compile the changelog, you can compare the changes between the base branch for the release (usually main) against the latest release, by checking https://github.com/revenuecat/purchases-ios/compare/<latest_release>...<base_branch>. For example, https://github.com/revenuecat/purchases-ios/compare/4.1.0...main.
    4. A new branch and PR will automatically be created
3. When the PR is approved, approve the hold job created in CircleCI. CircleCI will create a tag for the version. Alternatively, you can tag the last commit in the release branch and push it to the repository.
4. The rest will be performed automatically by CircleCI. If the automation fails, you can revert to manually calling `bundle exec fastlane deploy`.
5. The release branch PR can be merged after the release is completed.

##### Hotfixes:
Sometimes you might need to release a patch on a version that's not the latest. Or sometimes there might have been commits on `main` that shouldn't be released, but the latest version has a big bug. For example, let's say the last version is 4.0.0, but there's a bug on 3.9.0 that needs to be released as a 3.9.1:
1. Open a PR with the fix, merge it to `main`.
1. Jump to 3.9.0 and create a new branch `release/3.9.0`. Push this branch since it will be used as base for the PR you will open in the next steps.
1. Run `bundle exec fastlane ios bump` as you would do with any release. This will create a new PR `release/3.9.1`. Make sure the base branch of the PR is pointing to `release/3.9.0` and that the PR is labeled with **DO NOT MERGE** (add it to the title too so it's not merged by mistake)
1. Locally, while in branch the release branch (`release/3.9.1` in this case), cherry pick the changes with your fix that you just merged to `main` using `git cherry-pick <sha_of_the_squashed_commit_in_main>`. Fix any conflicts if there are any. Push the cherry picked commit to the remote branch `release/3.9.1`.
1. When the PR is approved, **DO NOT MERGE IT**. Approve the hold job in CircleCI as you would do for any other release. If there is no hold job because the release is older than when we introduced that job, manually tag the last commit in `release/3.9.1` with `3.9.1`.
1. CircleCI will start the deployment process
1. Close the PR after the release has been completed and delete both `release/3.9.0` and `release/3.9.1` branches.
1. Remember to edit the CHANGELOG.md in `main` to include the version that has been just released
