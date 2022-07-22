jira.check(
  key: ["CSDK", "CF", "SDKONCALL"],
  url: "https://revenuecats.atlassian.net/browse",
  search_title: true,
  search_commits: false,
  fail_on_warning: false,
  report_missing: true,
  skippable: true # skippable by adding [no-jira] to PR title or body
)

supported_types = ["breaking", "build", "ci", "docs", "feat", "fix", "perf", "refactor", "style", "test"]
supported_labels_in_pr = supported_types & github.pr_labels
no_supported_label = supported_labels_in_pr.empty?
if no_supported_label
  fail("Label the PR using one of the change type labels: #{supported_types}")
end