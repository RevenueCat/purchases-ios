# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
no_changelog = github.pr_title.include? "[no-changelog]"

# Add a CHANGELOG entry for app changes
if !git.modified_files.include?("CHANGELOG.latest.md") && !no_changelog
    warn("Please include a CHANGELOG entry. \nYou can find it at [CHANGELOG.latest.md](https://github.com/RevenueCat/purchases-ios/blob/main/CHANGELOG.latest.md). Add [no-changelog] to the PR title to skip this check.")
end

jira.check(
  key: ["CSDK", "CF", "SDKONCALL"],
  url: "https://revenuecats.atlassian.net/browse",
  search_title: true,
  search_commits: false,
  fail_on_warning: false,
  report_missing: true,
  skippable: true
)