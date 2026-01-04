# Xcode Project Settings Reference

## Target Configuration

### iOS Target (ItoriApp)

#### General Tab
```
Display Name: Itori
Bundle Identifier: com.yourcompany.roots
Version: 1.0
Build: 1

Deployment Info:
  - iOS: 17.0 (minimum)
  - Devices: iPhone, iPad
  - Orientation: Portrait, Landscape

App Category: Productivity

Frameworks, Libraries, and Embedded Content:
  + ItoriShared.framework (Do Not Embed)
```

#### Signing & Capabilities
```
Signing:
  ✓ Automatically manage signing
  Team: Your Team
  Bundle Identifier: com.yourcompany.roots

Capabilities:
  (None initially - add later as needed)
  
Future Capabilities:
  - iCloud (CloudKit)
  - In-App Purchase
  - Push Notifications
```

#### Build Settings (Key Values)
```
Product Name: ItoriApp
Product Module Name: ItoriApp
Swift Language Version: Swift 5
iOS Deployment Target: 17.0

Swift Compiler - Code Generation:
  Optimization Level (Debug): -Onone
  Optimization Level (Release): -O

Apple Clang - Code Generation:
  Enable Bitcode: No

Linking:
  Other Linker Flags: (inherit)

Search Paths:
  Framework Search Paths: (inherit)
  Header Search Paths: (inherit)
```

#### Info.plist Key Values
```xml
<key>CFBundleDisplayName</key>
<string>Itori</string>

<key>UILaunchScreen</key>
<dict/>

<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>

<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>

<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <true/>
</dict>
```

---

### macOS Target (ItoriMac)

#### General Tab
```
Display Name: Itori
Bundle Identifier: com.yourcompany.roots.mac
Version: 1.0
Build: 1

Deployment Info:
  - macOS: 14.0 (minimum)

App Category: Productivity

Frameworks, Libraries, and Embedded Content:
  + ItoriShared.framework (Do Not Embed)
```

#### Signing & Capabilities
```
Signing:
  ✓ Automatically manage signing
  Team: Your Team
  Bundle Identifier: com.yourcompany.roots.mac

Capabilities:
  ✓ App Sandbox
    - User Selected Files: Read/Write
  
Future Capabilities:
  - iCloud (CloudKit)
  - In-App Purchase
  - Push Notifications
```

#### Build Settings (Key Values)
```
Product Name: ItoriMac
Product Module Name: ItoriMac
Swift Language Version: Swift 5
macOS Deployment Target: 14.0

Swift Compiler - Code Generation:
  Optimization Level (Debug): -Onone
  Optimization Level (Release): -O

Linking:
  Other Linker Flags: (inherit)

Search Paths:
  Framework Search Paths: (inherit)
  Header Search Paths: (inherit)
```

#### Info.plist Key Values
```xml
<key>CFBundleDisplayName</key>
<string>Itori</string>

<key>LSMinimumSystemVersion</key>
<string>14.0</string>

<key>LSApplicationCategoryType</key>
<string>public.app-category.productivity</string>

<key>NSHumanReadableCopyright</key>
<string>Copyright © 2025 Your Company. All rights reserved.</string>
```

---

## Swift Package (ItoriShared)

### Package.swift Configuration

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ItoriShared",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ItoriShared",
            targets: ["ItoriShared"]
        )
    ],
    dependencies: [
        // Add cross-platform dependencies here
    ],
    targets: [
        .target(
            name: "ItoriShared",
            dependencies: [],
            path: "Sources/ItoriShared",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ItoriSharedTests",
            dependencies: ["ItoriShared"],
            path: "Tests/ItoriSharedTests"
        )
    ]
)
```

### Directory Structure (Exact)

```
ItoriShared/
├── Package.swift
├── README.md
├── Sources/
│   └── ItoriShared/
│       ├── Models/
│       ├── Services/
│       │   └── Protocols/
│       ├── Persistence/
│       ├── Utilities/
│       ├── DesignTokens/
│       ├── Localization/
│       └── DependencyInjection/
└── Tests/
    └── ItoriSharedTests/
```

---

## Scheme Configuration

### iOS Scheme (ItoriApp)

```
Build:
  ✓ ItoriApp (Target)
  ✓ ItoriShared (Package)

Run:
  Build Configuration: Debug
  Executable: ItoriApp.app
  Debugger: LLDB
  Launch: Automatically

Test:
  Build Configuration: Debug
  Test Targets:
    ✓ ItoriAppTests
    ✓ ItoriSharedTests

Profile:
  Build Configuration: Release

Analyze:
  Build Configuration: Debug

Archive:
  Build Configuration: Release
```

### macOS Scheme (ItoriMac)

```
Build:
  ✓ ItoriMac (Target)
  ✓ ItoriShared (Package)

Run:
  Build Configuration: Debug
  Executable: ItoriMac.app
  Debugger: LLDB
  Launch: Automatically

Test:
  Build Configuration: Debug
  Test Targets:
    ✓ ItoriMacTests
    ✓ ItoriSharedTests

Profile:
  Build Configuration: Release

Analyze:
  Build Configuration: Debug

Archive:
  Build Configuration: Release
```

---

## Asset Catalog Configuration

### iOS Assets.xcassets

```
Assets.xcassets/
├── AccentColor.colorset/
│   └── Contents.json
├── AppIcon.appiconset/
│   ├── Contents.json
│   └── (icon files for iPhone/iPad)
└── (other assets)
```

**Contents.json for AccentColor**:
```json
{
  "colors" : [
    {
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

### macOS Assets.xcassets

```
Assets.xcassets/
├── AccentColor.colorset/
│   └── Contents.json
├── AppIcon.appiconset/
│   ├── Contents.json
│   └── (icon files for macOS)
└── (other assets)
```

---

## Entitlements Configuration

### iOS Entitlements (Itori.entitlements)

**Minimal Configuration**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.yourcompany.roots</string>
    </array>
</dict>
</plist>
```

**With CloudKit** (add later):
```xml
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.yourcompany.roots</string>
    </array>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.yourcompany.roots</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
</dict>
```

### macOS Entitlements (ItoriMac.entitlements)

**Minimal Configuration**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.yourcompany.roots</string>
    </array>
</dict>
</plist>
```

**With CloudKit** (add later):
```xml
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.yourcompany.roots</string>
    </array>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.yourcompany.roots</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
</dict>
</plist>
```

---

## Xcode Workspace Settings

### Recommended Settings

**Editor → Text Editing**:
```
✓ Line numbers
✓ Code folding ribbon
✓ Page guide at column: 120
✓ Indent using: Spaces
  Tab width: 4 spaces
  Indent width: 4 spaces
```

**Behaviors**:
```
Running starts:
  → Show debugger with Console View

Testing completes:
  → Play sound: Glass
```

**Locations**:
```
Derived Data: Default
Archives: Default
```

---

## Build Configurations

### Debug Configuration
```
Swift Optimization Level: -Onone
Swift Compilation Mode: Incremental
Active Compilation Conditions: DEBUG
Other Swift Flags: -DDEBUG
Generate Debug Symbols: Yes
```

### Release Configuration
```
Swift Optimization Level: -O
Swift Compilation Mode: Whole Module
Active Compilation Conditions: RELEASE
Other Swift Flags: -DRELEASE
Generate Debug Symbols: No
Strip Swift Symbols: Yes
```

---

## Version Control (.gitignore)

```gitignore
# Xcode
*.xcodeproj/xcuserdata/
*.xcodeproj/project.xcworkspace/xcuserdata/
*.xcworkspace/xcuserdata/

# Build
/Build/
/DerivedData/

# Swift Package Manager
.swiftpm/
.build/
*.xcworkspace

# macOS
.DS_Store

# SwiftPM Package.resolved
Package.resolved

# Xcode Patch
*.xcodeproj.zip
*.xcworkspace.zip
```

---

## Command Line Build & Test

### Build iOS
```bash
xcodebuild \
  -project Itori.xcodeproj \
  -scheme ItoriApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build
```

### Build macOS
```bash
xcodebuild \
  -project Itori.xcodeproj \
  -scheme ItoriMac \
  -sdk macosx \
  build
```

### Test Shared Package
```bash
cd ItoriShared
swift test
```

### Test Both Targets
```bash
xcodebuild \
  -project Itori.xcodeproj \
  -scheme ItoriApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  test

xcodebuild \
  -project Itori.xcodeproj \
  -scheme ItoriMac \
  -sdk macosx \
  test
```

---

## Troubleshooting Common Issues

### Issue: Package not found
**Solution**: 
1. File → Packages → Reset Package Caches
2. Clean build folder (⇧⌘K)
3. Rebuild

### Issue: Duplicate symbol errors
**Solution**:
1. Ensure code is only in one place (shared OR target, not both)
2. Check for accidental file inclusion in both targets
3. Verify platform guards (`#if os(...)`)

### Issue: Can't import ItoriShared
**Solution**:
1. Verify package is added to target dependencies
2. Check `import ItoriShared` statement is correct
3. Rebuild package explicitly

### Issue: Different behavior on iOS vs macOS
**Solution**:
1. Check platform-specific extensions are correct
2. Verify protocol implementations differ appropriately
3. Test platform-specific code paths

---

## Next Steps After Setup

1. **Verify Build**
   ```bash
   xcodebuild -project Itori.xcodeproj -scheme ItoriApp build
   xcodebuild -project Itori.xcodeproj -scheme ItoriMac build
   ```

2. **Run Tests**
   ```bash
   cd ItoriShared && swift test
   ```

3. **Add First Shared Model**
   - Create `Course.swift` in `ItoriShared/Sources/ItoriShared/Models/`
   - Import in both targets
   - Verify compilation

4. **Create Platform Extension**
   - Add `Color+iOS.swift` with `Course.color` extension
   - Add `Color+macOS.swift` with `Course.color` extension
   - Test color rendering

5. **Setup Dependency Injection**
   - Create `AppContainer` in ItoriShared
   - Create platform-specific `AppDependencies`
   - Wire up in app entry points

**You're now ready to build a multi-platform app with maximum code sharing! 🚀**
