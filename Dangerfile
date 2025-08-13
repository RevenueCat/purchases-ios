danger.import_dangerfile(github: 'RevenueCat/Dangerfile')

# Check for submodules
submodules = `git submodule status`.strip
if !submodules.empty?
  fail("This repository should not contain any submodules. When using Swift Package Manager, developers will get a resolution error because SPM cannot access private submodules.")
end

# Check for new Swift files that aren't added to RevenueCat.xcodeproj
def check_swift_files_in_project
  project_file = 'RevenueCat.xcodeproj/project.pbxproj'
  
  unless File.exist?(project_file)
    warn("RevenueCat.xcodeproj/project.pbxproj not found")
    return
  end
  
  # Get all added Swift files in this PR
  added_swift_files = git.added_files.select { |file| file.end_with?('.swift') }
  
  return if added_swift_files.empty?
  
  # Check which added Swift files are not referenced in the project using grep
  missing_files = added_swift_files.select do |swift_file|
    filename = File.basename(swift_file)
    # Use grep to search for the filename in the project.pbxproj
    # Look for patterns like "/* FileName.swift in Sources */" or "/* FileName.swift */"
    result = `grep -q "\/\\* #{Regexp.escape(filename)} " "#{project_file}"`
    $?.exitstatus != 0  # grep returns 0 if found, non-zero if not found
  end
  
  unless missing_files.empty?
    message = "The following Swift files were added but don't appear to be included in RevenueCat.xcodeproj:\n"
    missing_files.each { |file| message += "• #{file}\n" }
    message += "\nPlease make sure to add these files to the Xcode project, or verify they should be excluded (e.g., if they're in test directories that use a different project)."
    warn(message)
  end
end

check_swift_files_in_project
