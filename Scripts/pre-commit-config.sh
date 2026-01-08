#!/bin/bash
#
# Configuration loader for pre-commit hooks
# Source this file to load configuration
#

# Default configuration
CHECK_MERGE_CONFLICTS=${CHECK_MERGE_CONFLICTS:-true}
CHECK_LARGE_FILES=${CHECK_LARGE_FILES:-true}
CHECK_PRINT_STATEMENTS=${CHECK_PRINT_STATEMENTS:-true}
CHECK_BUILD=${CHECK_BUILD:-true}
CHECK_SECURITY=${CHECK_SECURITY:-true}
CHECK_TODO_FIXME=${CHECK_TODO_FIXME:-true}
CHECK_SWIFT_PACKAGE=${CHECK_SWIFT_PACKAGE:-true}
CHECK_ASSETS=${CHECK_ASSETS:-true}
CHECK_SWIFTLINT=${CHECK_SWIFTLINT:-true}
CHECK_VERSION_SYNC=${CHECK_VERSION_SYNC:-true}
CHECK_THREADING=${CHECK_THREADING:-true}
CHECK_ACCESSIBILITY=${CHECK_ACCESSIBILITY:-true}
CHECK_LOCALIZATION=${CHECK_LOCALIZATION:-true}
MAX_FILE_SIZE=${MAX_FILE_SIZE:-5242880}
BUILD_CACHE_MINUTES=${BUILD_CACHE_MINUTES:-5}

# Load custom configuration if exists
if [ -f ".git-hooks-config" ]; then
    source .git-hooks-config
fi

# Helper function to check if a check is enabled
is_enabled() {
    local check_name=$1
    local check_value=$(eval echo \$"$check_name")
    [[ "$check_value" == "true" ]]
}

export CHECK_MERGE_CONFLICTS
export CHECK_LARGE_FILES
export CHECK_PRINT_STATEMENTS
export CHECK_BUILD
export CHECK_SECURITY
export CHECK_TODO_FIXME
export CHECK_SWIFT_PACKAGE
export CHECK_ASSETS
export CHECK_SWIFTLINT
export CHECK_VERSION_SYNC
export CHECK_THREADING
export CHECK_ACCESSIBILITY
export CHECK_LOCALIZATION
export MAX_FILE_SIZE
export BUILD_CACHE_MINUTES
