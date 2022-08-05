def fail_if_no_supported_label_found
  supported_types = ["breaking", "build", "ci", "docs", "feat", "fix", "perf", "refactor", "style", "test"]

  supported_labels_in_pr = supported_types & github.pr_labels
  no_supported_label = supported_labels_in_pr.empty?
  if no_supported_label
    fail("Label the PR using one of the change type labels: #{supported_types}")
  end
end

fail_if_no_supported_label_found
