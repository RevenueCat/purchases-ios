danger.import_dangerfile(github: 'RevenueCat/Dangerfile')

# Check for submodules
submodules = `git submodule status`.strip
if !submodules.empty?
  fail("This repository should not contain any submodules. When using Swift Package Manager, developers will get a resolution error because SPM cannot access private submodules.")
end
