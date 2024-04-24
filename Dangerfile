# danger.import_dangerfile(github: 'RevenueCat/purchases-test')

require 'shellwords'

#### GITHUB LABEL CHECK
def fail_if_no_supported_label_found
  supported_types = ["breaking", "build", "ci", "docs", "feat", "fix", "perf", "refactor", "RevenueCatUI", "style", "test", "next_release", "dependencies", "phc_dependencies"]

  supported_labels_in_pr = supported_types & github.pr_labels
  no_supported_label = supported_labels_in_pr.empty?
  if no_supported_label
    fail("Label the PR using one of the change type labels")
    markdown <<-MARKDOWN
  | Label | Description |
  |-------|-------------|
  | *breaking* | Changes that are breaking |
  | *build* | Changes that affect the build system |
  | *ci* | Changes to our CI configuration files and scripts |
  | *docs* | Documentation only changes |
  | *feat* | A new feature |
  | *fix* | A bug fix |
  | *perf* | A code change that improves performance |
  | *RevenueCatUI* | A change to the RevenueCatUI library |
  | *refactor* | A code change that neither fixes a bug nor adds a feature |
  | *style* | Changes that don't affect the meaning of the code (white-space, formatting, missing semi-colons, etc |
  | *test* | Adding missing tests or correcting existing tests |
  | *next_release* | Preparing a new release |
  | *dependencies* | Updating a dependency |
  | *phc_dependencies* | Updating purchases-hybrid-common dependency |
  MARKDOWN
  end
end

#### PR SIZE INCREASE CHECK

# Thresholds
WARN_SIZE_INCREASE = 102400  # 100kb
FAIL_SIZE_INCREASE = 256000  # 250kb

# Bypass
BYPASS_LABEL = "danger-bypass-size-limit"

def check_pr_size_increase
  added_and_modified_files = git.added_files + git.modified_files
  total_size_increase = calculate_total_size_increase(added_and_modified_files)

  bypass_size_check = github.pr_labels.any? { |s| s == BYPASS_LABEL }

  if bypass_size_check
    warn("Size check is being bypassed due to the presence of the label \"#{BYPASS_LABEL}\"")
    if total_size_increase > WARN_SIZE_INCREASE
      warn("Size increase: #{'%.2f' % toKB(total_size_increase)} KB")
    else
      message("Size increase: #{'%.2f' % toKB(total_size_increase)} KB")
    return
  end

  if total_size_increase > FAIL_SIZE_INCREASE
    fail("This PR increases the size of the repo by more than #{'%.2f' % toKB(FAIL_SIZE_INCREASE)} KB (increased by #{'%.2f' % toKB(total_size_increase)} KB).")
  elsif total_size_increase > WARN_SIZE_INCREASE
    warn("This PR increases the size of the repo by more than #{'%.2f' % toKB(WARN_SIZE_INCREASE)} KB (increased by #{'%.2f' % toKB(total_size_increase)} KB).")
  else
    message("Size increase: #{'%.2f' % toKB(total_size_increase)} KB")
  end
end

def toKB(bytes)
  bytes / 1024.0
end

def calculate_total_size_increase(files)
  total_increase = 0
  files.each do |file|
    file_size_in_branch = size_of_file(file)
    file_size_in_main = size_of_file_in_main(file)
    size_increase = file_size_in_branch - file_size_in_main
    total_increase += size_increase if size_increase > 0
  end
  total_increase
end

# File size in the current branch
def size_of_file(file_path)
  if File.exists?(file_path)
    File.size(file_path)
  else
    0
  end
end

# File size in main branch
def size_of_file_in_main(file)
  escaped_file = Shellwords.shellescape(file)
  if system("git cat-file -e main:#{escaped_file} 2> /dev/null")
    `git show main:#{escaped_file} 2>/dev/null | wc -c`.to_i
  else
    0
  end
end

#### ENTRY POINT

# Fail when GitHub PR label is missing
fail_if_no_supported_label_found

# Fail/warn when PR size increase exceeds threshold
check_pr_size_increase
