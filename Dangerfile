danger.import_dangerfile(github: 'RevenueCat/Dangerfile')

require 'pathname'
require 'set'

# Check for submodules
submodules = `git submodule status`.strip
if !submodules.empty?
  fail("This repository should not contain any submodules. When using Swift Package Manager, developers will get a resolution error because SPM cannot access private submodules.")
end

# Check for new Swift files that aren't added to RevenueCat.xcodeproj
def normalize_path(path)
  Pathname(path).cleanpath.to_s.sub(%r{\A\./}, '')
end

def relevant_swift_file?(path)
  path = normalize_path(path)
  path.end_with?('.swift') &&
    (path.start_with?('Sources/') || path.start_with?('RevenueCatUI/') || path.start_with?('Tests/'))
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
  warn("xcodeproj gem not available; skipping RevenueCat.xcodeproj sync check")
  nil
rescue StandardError => e
  warn("Unable to read #{project_file}: #{e.message}")
  nil
end

def check_swift_files_in_project
  project_file = 'RevenueCat.xcodeproj'
  
  unless File.exist?(project_file)
    warn("RevenueCat.xcodeproj not found")
    return
  end
  
  project_swift_files = project_swift_file_paths(project_file)
  return if project_swift_files.nil?
  
  added_swift_files = git.added_files
    .select { |file| relevant_swift_file?(file) }
    .map { |file| normalize_path(file) }
  
  deleted_swift_files = git.deleted_files
    .select { |file| relevant_swift_file?(file) }
    .map { |file| normalize_path(file) }
  
  missing_files = added_swift_files.reject { |file| project_swift_files.include?(file) }
  lingering_references = deleted_swift_files.select { |file| project_swift_files.include?(file) }

  return if missing_files.empty? && lingering_references.empty?

  message = "Please keep RevenueCat.xcodeproj in sync with Tuist-generated changes.\n"
  unless missing_files.empty?
    message += "\nThe following Swift files were added but don't appear to be included in RevenueCat.xcodeproj:\n"
    missing_files.each { |file| message += "• #{file}\n" }
  end

  unless lingering_references.empty?
    message += "\nThe following Swift files were deleted but still appear referenced in RevenueCat.xcodeproj:\n"
    lingering_references.each { |file| message += "• #{file}\n" }
  end

  message += "\nIf you've changed files using the tuist project, make sure those changes are added to RevenueCat.xcodeproj, or double-check if they should be excluded."
  warn(message)
end

check_swift_files_in_project
