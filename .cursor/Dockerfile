# Cloud Agent environment for purchases-ios.
#
# NOTE: iOS/Swift code cannot be compiled in this Linux container (no Xcode or
# Apple toolchain). This image only provides the Ruby toolchain so agents can
# run fastlane lanes that don't require building Swift code.
FROM cimg/ruby:3.2.0

# The agent runtime injects a bundled `/exec-daemon/ssh-keygen` (used to sign git
# commits) ahead of the system binaries on PATH, but that bundled binary requires
# a newer glibc than this image provides, so commit signing fails. We can't move
# /exec-daemon off the front of PATH from here (the runtime prepends it after the
# image is built), but $HOME/bin is placed *before* /exec-daemon on PATH, so we
# shadow the broken binary with the image's working OpenSSH ssh-keygen.
RUN mkdir -p "$HOME/bin" && ln -sf /usr/bin/ssh-keygen "$HOME/bin/ssh-keygen"
