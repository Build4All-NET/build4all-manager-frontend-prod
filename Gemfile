source "https://rubygems.org"

# Ruby tooling used by the iOS pipeline (see .github/workflows/ios_testflight.yml).
#
# Keep these here rather than relying on bare `gem install` in CI: fastlane and
# CocoaPods share a large set of transitive dependencies (excon, ffi, xcodeproj,
# activesupport, ...) and only a resolver that sees every gem at once can pick
# versions that satisfy all of them. `gem install ... --force` skips dependency
# checks altogether, which left the CI gem home in a state RubyGems could not
# activate — `fastlane --version` died in the resolver on `excon (= 1.7.0)`.

gem "cocoapods", "~> 1.16"
gem "fastlane", "~> 2.228"
gem "xcodeproj", "~> 1.27"
