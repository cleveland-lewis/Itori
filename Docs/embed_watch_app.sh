#!/bin/bash

# Script to configure watchOS companion app embedding
# This modifies the Xcode project to make the watch app install with the iOS app

set -e

PROJECT_FILE="ItoriApp.xcodeproj/project.pbxproj"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "watchOS Companion App Embedding Setup"
echo "========================================="
echo ""

# Backup
BACKUP_FILE="$PROJECT_FILE.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}📦 Creating backup: $BACKUP_FILE${NC}"
cp "$PROJECT_FILE" "$BACKUP_FILE"

# Generate UUIDs (24 hex chars for Xcode)
COPY_FILES_UUID=$(uuidgen | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')
TARGET_DEP_UUID=$(uuidgen | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')
CONTAINER_PROXY_UUID=$(uuidgen | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')
BUILD_FILE_UUID=$(uuidgen | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')

echo -e "${YELLOW}🔑 Generated UUIDs:${NC}"
echo "   Copy Files Phase: $COPY_FILES_UUID"
echo "   Target Dependency: $TARGET_DEP_UUID"
echo "   Container Proxy: $CONTAINER_PROXY_UUID"
echo "   Build File: $BUILD_FILE_UUID"
echo ""

# Extract existing UUIDs from project
IOS_TARGET_UUID="1AD7D4332EDD328800D403F3"
WATCH_TARGET_UUID="A3D4E93275A547E499CA3B3E"
WATCH_PRODUCT_UUID="9BBB386A3C3046FCA7A3D6DB"
PROJECT_UUID="1AD7D42C2EDD328800D403F3"

echo -e "${YELLOW}📋 Found existing UUIDs:${NC}"
echo "   iOS Target: $IOS_TARGET_UUID"
echo "   Watch Target: $WATCH_TARGET_UUID"
echo "   Watch Product: $WATCH_PRODUCT_UUID"
echo "   Project: $PROJECT_UUID"
echo ""

if [ -z "$WATCH_TARGET_UUID" ] || [ -z "$WATCH_PRODUCT_UUID" ]; then
    echo -e "${RED}❌ Error: Could not find watchOS target or product${NC}"
    exit 1
fi

# Create temporary file for modifications
TEMP_FILE=$(mktemp)
cp "$PROJECT_FILE" "$TEMP_FILE"

# 1. Add PBXContainerItemProxy if needed
if ! grep -q "Begin PBXContainerItemProxy section" "$TEMP_FILE"; then
    echo -e "${YELLOW}➕ Adding PBXContainerItemProxy section${NC}"
    sed -i.tmp "/Begin PBXCopyFilesBuildPhase section/i\\
/* Begin PBXContainerItemProxy section */\\
		$CONTAINER_PROXY_UUID /* PBXContainerItemProxy */ = {\\
			isa = PBXContainerItemProxy;\\
			containerPortal = $PROJECT_UUID /* Project object */;\\
			proxyType = 1;\\
			remoteGlobalIDString = $WATCH_TARGET_UUID;\\
			remoteInfo = ItoriWatch;\\
		};\\
/* End PBXContainerItemProxy section */\\
\\
" "$TEMP_FILE"
    rm -f "$TEMP_FILE.tmp"
else
    echo -e "${YELLOW}➕ Adding to existing PBXContainerItemProxy section${NC}"
    sed -i.tmp "/Begin PBXContainerItemProxy section/a\\
		$CONTAINER_PROXY_UUID /* PBXContainerItemProxy */ = {\\
			isa = PBXContainerItemProxy;\\
			containerPortal = $PROJECT_UUID /* Project object */;\\
			proxyType = 1;\\
			remoteGlobalIDString = $WATCH_TARGET_UUID;\\
			remoteInfo = ItoriWatch;\\
		};
" "$TEMP_FILE"
    rm -f "$TEMP_FILE.tmp"
fi

# 2. Add PBXBuildFile for watch product
echo -e "${YELLOW}➕ Adding PBXBuildFile for watch app${NC}"
sed -i.tmp "/Begin PBXBuildFile section/a\\
		$BUILD_FILE_UUID /* ItoriWatch.app in Embed Watch Content */ = {isa = PBXBuildFile; fileRef = $WATCH_PRODUCT_UUID /* ItoriWatch.app */; settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); }; };
" "$TEMP_FILE"
rm -f "$TEMP_FILE.tmp"

# 3. Add PBXCopyFilesBuildPhase
if ! grep -q "Begin PBXCopyFilesBuildPhase section" "$TEMP_FILE"; then
    echo -e "${YELLOW}➕ Creating PBXCopyFilesBuildPhase section${NC}"
    sed -i.tmp "/Begin PBXFileReference section/i\\
/* Begin PBXCopyFilesBuildPhase section */\\
		$COPY_FILES_UUID /* Embed Watch Content */ = {\\
			isa = PBXCopyFilesBuildPhase;\\
			buildActionMask = 2147483647;\\
			dstPath = \"\$(CONTENTS_FOLDER_PATH)/Watch\";\\
			dstSubfolderSpec = 16;\\
			files = (\\
				$BUILD_FILE_UUID /* ItoriWatch.app in Embed Watch Content */,\\
			);\\
			name = \"Embed Watch Content\";\\
			runOnlyForDeploymentPostprocessing = 0;\\
		};\\
/* End PBXCopyFilesBuildPhase section */\\
\\
" "$TEMP_FILE"
    rm -f "$TEMP_FILE.tmp"
else
    echo -e "${YELLOW}➕ Adding to existing PBXCopyFilesBuildPhase section${NC}"
    sed -i.tmp "/Begin PBXCopyFilesBuildPhase section/a\\
		$COPY_FILES_UUID /* Embed Watch Content */ = {\\
			isa = PBXCopyFilesBuildPhase;\\
			buildActionMask = 2147483647;\\
			dstPath = \"\$(CONTENTS_FOLDER_PATH)/Watch\";\\
			dstSubfolderSpec = 16;\\
			files = (\\
				$BUILD_FILE_UUID /* ItoriWatch.app in Embed Watch Content */,\\
			);\\
			name = \"Embed Watch Content\";\\
			runOnlyForDeploymentPostprocessing = 0;\\
		};
" "$TEMP_FILE"
    rm -f "$TEMP_FILE.tmp"
fi

# 4. Add PBXTargetDependency
if ! grep -q "Begin PBXTargetDependency section" "$TEMP_FILE"; then
    echo -e "${YELLOW}➕ Creating PBXTargetDependency section${NC}"
    sed -i.tmp "/Begin PBXVariantGroup section/i\\
/* Begin PBXTargetDependency section */\\
		$TARGET_DEP_UUID /* PBXTargetDependency */ = {\\
			isa = PBXTargetDependency;\\
			target = $WATCH_TARGET_UUID /* ItoriWatch */;\\
			targetProxy = $CONTAINER_PROXY_UUID /* PBXContainerItemProxy */;\\
		};\\
/* End PBXTargetDependency section */\\
\\
" "$TEMP_FILE"
    rm -f "$TEMP_FILE.tmp"
else
    echo -e "${YELLOW}➕ Adding to existing PBXTargetDependency section${NC}"
    sed -i.tmp "/Begin PBXTargetDependency section/a\\
		$TARGET_DEP_UUID /* PBXTargetDependency */ = {\\
			isa = PBXTargetDependency;\\
			target = $WATCH_TARGET_UUID /* ItoriWatch */;\\
			targetProxy = $CONTAINER_PROXY_UUID /* PBXContainerItemProxy */;\\
		};
" "$TEMP_FILE"
    rm -f "$TEMP_FILE.tmp"
fi

# 5. Add Copy Files phase to iOS target's buildPhases
echo -e "${YELLOW}🔧 Adding Embed Watch Content to iOS target buildPhases${NC}"
# Find the iOS target's buildPhases and add our copy phase
sed -i.tmp "/$IOS_TARGET_UUID \/\* Itori \*\/ = {/,/buildPhases = (/,/);/{
    /1AD7D4322EDD328800D403F3 \/\* Resources \*\//a\\
				$COPY_FILES_UUID /* Embed Watch Content */,
}" "$TEMP_FILE"
rm -f "$TEMP_FILE.tmp"

# 6. Add target dependency to iOS target's dependencies
echo -e "${YELLOW}🔗 Adding ItoriWatch dependency to iOS target${NC}"
sed -i.tmp "/$IOS_TARGET_UUID \/\* Itori \*\/ = {/,/dependencies = (/,/);/{
    /dependencies = (/a\\
				$TARGET_DEP_UUID /* PBXTargetDependency */,
}" "$TEMP_FILE"
rm -f "$TEMP_FILE.tmp"

# Copy result back
cp "$TEMP_FILE" "$PROJECT_FILE"
rm -f "$TEMP_FILE"

echo ""
echo -e "${GREEN}✅ Successfully configured watchOS companion app embedding!${NC}"
echo ""
echo "Next steps:"
echo "  1. Open Xcode: open ItoriApp.xcodeproj"
echo "  2. Clean build folder: Shift+Cmd+K"
echo "  3. Build iOS app: Cmd+B"
echo "  4. Run on simulator: Cmd+R"
echo ""
echo "The watchOS app will now install automatically with the iOS app."
echo ""
echo "To verify:"
echo "  - Select 'Itori' target → 'Build Phases'"
echo "  - Look for 'Embed Watch Content' phase"
echo "  - It should contain 'ItoriWatch.app'"
echo ""
echo "If something goes wrong, restore backup:"
echo "  cp \"$BACKUP_FILE\" \"$PROJECT_FILE\""
echo ""
