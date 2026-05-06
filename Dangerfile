danger.import_dangerfile(github: 'RevenueCat/Dangerfile')

require 'pathname'
require 'set'

EXCLUDED_SWIFT_PATH_PREFIXES = [
  'Tests/APITesters/'
].freeze

COMMENT_MARKER = "<!-- purchases-ios-danger -->"

def normalize_path(path)
  Pathname(path).cleanpath.to_s.sub(%r{\A\./}, '')
end

def relevant_swift_file?(path)
  path = normalize_path(path)
  return false unless path.end_with?('.swift')
  return false if EXCLUDED_SWIFT_PATH_PREFIXES.any? { |prefix| path.start_with?(prefix) }

  in_project_sources = path.start_with?('Sources/') || path.start_with?('RevenueCatUI/')
  in_tests = path.start_with?('Tests/')

  in_project_sources || in_tests
end

def project_swift_file_paths(project_file)
  require 'xcodeproj'

  project = Xcodeproj::Project.open(project_file)
  root = Pathname.pwd

  project.files
         .map { |file| file.real_path if file.path }
         .compact
         .select { |path| path.extname == '.swift' }
         .map { |path| normalize_path(path.cleanpath.relative_path_from(root).to_s) }
         .to_set
rescue LoadError
  nil
rescue StandardError
  nil
end

def xcodeproj_messages
  failures = []
  warnings = []

  project_file = 'RevenueCat.xcodeproj'

  unless File.exist?(project_file)
    warnings << "RevenueCat.xcodeproj not found"
    return [failures, warnings]
  end

  project_swift_files = project_swift_file_paths(project_file)
  return [failures, warnings] if project_swift_files.nil?

  added_swift_files = git.added_files
    .select { |file| relevant_swift_file?(file) }
    .map { |file| normalize_path(file) }

  deleted_swift_files = git.deleted_files
    .select { |file| relevant_swift_file?(file) }
    .map { |file| normalize_path(file) }

  missing_files = added_swift_files.reject { |file| project_swift_files.include?(file) }
  lingering_references = deleted_swift_files.select { |file| project_swift_files.include?(file) }

  return [failures, warnings] if missing_files.empty? && lingering_references.empty?

  message = "**`RevenueCat.xcodeproj` is out of sync.**\n"
  unless missing_files.empty?
    message += "\nThe following Swift files were added but are missing from `RevenueCat.xcodeproj`:\n"
    missing_files.each { |file| message += "• `#{file}`\n" }
  end
  unless lingering_references.empty?
    message += "\nThe following Swift files were deleted but still referenced in `RevenueCat.xcodeproj`:\n"
    lingering_references.each { |file| message += "• `#{file}`\n" }
  end
  message += "\nTo fix: open `RevenueCat.xcodeproj` in Xcode, add/remove the files above in the appropriate target. "
  message += "Check where similar files in the same directory are assigned if you're unsure which target to use."

  failures << message
  [failures, warnings]
end

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

f, w = xcodeproj_messages
all_failures.concat(f)
all_warnings.concat(w)

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
