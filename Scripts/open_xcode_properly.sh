#!/bin/bash

# Script to properly open Itori project in Xcode with schemes configured
# This will ensure the build button is visible

PROJECT_DIR="/Users/clevelandlewis/Desktop/Itori"
PROJECT_FILE="$PROJECT_DIR/ItoriApp.xcodeproj"

echo "🔧 Setting up Xcode project for Itori..."
echo ""

# Step 1: Kill any running Xcode instances
echo "1️⃣ Closing any open Xcode instances..."
killall Xcode 2>/dev/null
sleep 2

# Step 2: Clear Xcode caches for this project
echo "2️⃣ Clearing Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Itori-* 2>/dev/null
rm -rf ~/Library/Developer/Xcode/DerivedData/ItoriApp-* 2>/dev/null

# Step 3: Verify project file exists
if [ ! -d "$PROJECT_FILE" ]; then
    echo "❌ Error: Project file not found at $PROJECT_FILE"
    exit 1
fi

echo "3️⃣ Found project at: $PROJECT_FILE"

# Step 4: Verify schemes exist
SCHEMES_DIR="$PROJECT_FILE/xcshareddata/xcschemes"
if [ ! -f "$SCHEMES_DIR/Itori.xcscheme" ]; then
    echo "❌ Error: Itori.xcscheme not found"
    exit 1
fi

echo "4️⃣ Verified schemes exist"

# Step 5: Create a scheme management file to ensure schemes are recognized
SCHEME_MGMT="$PROJECT_FILE/xcshareddata/xcschemes/xcschememanagement.plist"
if [ ! -f "$SCHEME_MGMT" ]; then
    echo "5️⃣ Creating scheme management file..."
    cat > "$SCHEME_MGMT" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SchemeUserState</key>
	<dict>
		<key>Itori.xcscheme_^#shared#^_</key>
		<dict>
			<key>orderHint</key>
			<integer>0</integer>
		</dict>
		<key>ItoriTests.xcscheme_^#shared#^_</key>
		<dict>
			<key>orderHint</key>
			<integer>1</integer>
		</dict>
		<key>ItoriUITests.xcscheme_^#shared#^_</key>
		<dict>
			<key>orderHint</key>
			<integer>2</integer>
		</dict>
		<key>ItoriWatch.xcscheme_^#shared#^_</key>
		<dict>
			<key>orderHint</key>
			<integer>3</integer>
		</dict>
	</dict>
	<key>SuppressBuildableAutocreation</key>
	<dict>
		<key>1AD7D4332EDD328800D403F3</key>
		<dict>
			<key>primary</key>
			<true/>
		</dict>
	</dict>
</dict>
</plist>
EOF
else
    echo "5️⃣ Scheme management file already exists"
fi

# Step 6: Open Xcode with the project
echo "6️⃣ Opening Xcode..."
echo ""
open "$PROJECT_FILE"

# Wait a moment for Xcode to start
sleep 3

echo ""
echo "✅ Done! Xcode should now open with the Itori project."
echo ""
echo "📋 Next steps:"
echo "   1. Wait for Xcode to finish indexing (watch the progress bar)"
echo "   2. Look at the top toolbar - you should see the scheme selector"
echo "   3. Click the scheme dropdown and select 'Itori'"
echo "   4. Click the destination dropdown and select 'My Mac (Designed for iPad)' or 'My Mac'"
echo "   5. The build button (▶️) should now be visible and active!"
echo ""
echo "If you still don't see schemes, go to:"
echo "   Product > Scheme > Manage Schemes..."
echo "   and make sure 'Itori' is checked"
