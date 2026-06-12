danger.import_dangerfile(github: 'RevenueCat/Dangerfile')

COMMENT_MARKER = "<!-- purchases-ios-danger -->"

def public_enum_messages
  swift_files = (git.added_files + git.modified_files)
    .select { |file| file.start_with?('Sources/') || file.start_with?('RevenueCatUI/') }
    .select { |file| file.end_with?('.swift') }
    .select { |file| File.exist?(file) }

  public_enum_pattern = /^\+\s*public\s+enum\s+/
  spi_public_enum_pattern = /@_spi\([^)]*\)\s*public\s+enum/

  files_with_public_enums = []

  swift_files.each do |file|
    diff = git.diff_for_file(file)
    next unless diff

    diff.patch.each_line do |line|
      if line.match?(public_enum_pattern) && !line.match?(spi_public_enum_pattern)
        files_with_public_enums << file
        break
      end
    end
  end

  return [[], []] if files_with_public_enums.empty?

  message = "Public enums should not be added. Consider using a struct with static properties or an @objc enum instead.\n\n"
  message += "The following files contain new public enums:\n"
  files_with_public_enums.each { |file| message += "• #{file}\n" }

  [[], [message]]
end

# Collect all issues
all_failures = []
all_warnings = []

submodules = `git submodule status`.strip
unless submodules.empty?
  all_failures << "This repository should not contain any submodules. When using Swift Package Manager, developers will get a resolution error because SPM cannot access private submodules."
end

f, w = public_enum_messages
all_failures.concat(f)
all_warnings.concat(w)

# Manage a single sticky comment — edit it on each run, delete it when all checks pass
repo = github.pr_json["base"]["repo"]["full_name"]
pr_number = github.pr_json["number"]

existing_comment = github.api.issue_comments(repo, pr_number)
                           .find { |c| c.body.include?(COMMENT_MARKER) }

if all_failures.empty? && all_warnings.empty?
  github.api.delete_comment(repo, existing_comment.id) if existing_comment
else
  sections = [COMMENT_MARKER]
  unless all_failures.empty?
    sections << "### :x: Failures\n\n" + all_failures.join("\n\n---\n\n")
  end
  unless all_warnings.empty?
    sections << "### :warning: Warnings\n\n" + all_warnings.join("\n\n---\n\n")
  end
  body = sections.join("\n\n")

  if existing_comment
    github.api.update_comment(repo, existing_comment.id, body)
  else
    github.api.add_comment(repo, pr_number, body)
  end

  fail("Purchases iOS checks failed — see the comment above for details.") unless all_failures.empty?
end
