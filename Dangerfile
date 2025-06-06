danger.import_dangerfile(github: 'RevenueCat/Dangerfile')

# Check for submodules
submodules = `git submodule status`.strip
if !submodules.empty?
  fail("This repository should not contain any submodules. Please remove them.")
end
