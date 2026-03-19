#!/usr/bin/env bash
# Update hardcoded semver strings across documentation files before releasing.

set -e

NEW_VERSION=$1

if [ -z "$NEW_VERSION" ]; then
    echo "Error: No version provided by semantic-release exec plugin"
    exit 1
fi

echo "Updating references to v$NEW_VERSION..."

# Perl is used for safe, cross-platform in-place regex substitution (macOS/Ubuntu safe).
# This replaces `version-X.Y.Z-blue.svg` badges globally.
perl -pi -e "s/version-[0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9.]+)?-blue\.svg/version-${NEW_VERSION}-blue.svg/g" README.md

# This replaces any instances of `vX.Y.Z` globally (git branch, tags, headers).
perl -pi -e "s/v[0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9.]+)?/v${NEW_VERSION}/g" README.md

# Update internal plugin version variable
perl -pi -e "s/let g:claude_code_version = \"[0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9.]+)?\"/let g:claude_code_version = \"${NEW_VERSION}\"/g" plugin/claude_code.vim

# Update Vader test suite to match the new version
perl -pi -e "s/g:claude_code_version is set to [0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9.]+)?/g:claude_code_version is set to ${NEW_VERSION}/g" test/test_dispatch.vader
perl -pi -e "s/AssertEqual '[0-9]+\.[0-9]+\.[0-9]+(?:-[a-zA-Z0-9.]+)?', g:claude_code_version/AssertEqual '${NEW_VERSION}', g:claude_code_version/g" test/test_dispatch.vader

# Make sure we didn't inadvertently modify anything besides the semver strings!
echo "Version successfully updated across all files"
