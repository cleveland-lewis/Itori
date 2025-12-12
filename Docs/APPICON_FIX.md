# AppIcon Asset Catalog Fix

## Issue
The AppIcon asset catalog had incomplete configuration with only an iPhone icon slot defined, causing build warnings.

## Solution
Updated `Contents.json` to define proper macOS icon slots for all required sizes.

## Required Icon Sizes for macOS

The following icon files need to be created in the `SharedCore/DesignSystem/Assets.xcassets/AppIcon.appiconset/` directory:

| Filename | Size (pixels) | Purpose |
|----------|---------------|---------|
| AppIcon-16.png | 16x16 | macOS 1x |
| AppIcon-16@2x.png | 32x32 | macOS 2x |
| AppIcon-32.png | 32x32 | macOS 1x |
| AppIcon-32@2x.png | 64x64 | macOS 2x |
| AppIcon-128.png | 128x128 | macOS 1x |
| AppIcon-128@2x.png | 256x256 | macOS 2x |
| AppIcon-256.png | 256x256 | macOS 1x |
| AppIcon-256@2x.png | 512x512 | macOS 2x |
| AppIcon-512.png | 512x512 | macOS 1x |
| AppIcon-512@2x.png | 1024x1024 | macOS 2x |

## Generating Icons

### Option 1: Using Python Script (Recommended)
```bash
cd Scripts
pip3 install Pillow
python3 generate_appicons.py
```

### Option 2: Using Shell Script (Requires ImageMagick)
```bash
cd Scripts
chmod +x generate_appicons.sh
./generate_appicons.sh
```

### Option 3: Using Icon Generation Tools
Use professional tools like:
- **Image2icon** (macOS) - https://img2icnsapp.com/
- **IconFly** (macOS)
- **Online tool** - https://iconverticons.com/online/

Create a master 1024x1024 icon design, then generate all required sizes.

## Design Recommendations

### Icon Design Guidelines
1. **Simple and Recognizable**: Use a clean, minimal design that works at small sizes
2. **No Text** (except single letters): Text becomes unreadable at 16x16
3. **Bold Shapes**: Use strong, simple shapes with good contrast
4. **Color**: Use 2-3 colors maximum for clarity
5. **Padding**: Leave ~10% margin around the edges

### Suggested Design for Roots
- **Background**: Gradient from blue (#4A90E2) to purple (#7B68EE)
- **Icon**: White "R" or tree/root symbol
- **Style**: Modern, rounded corners
- **Feel**: Academic, organized, growth-oriented

## Temporary Workaround

If you need to build immediately without custom icons:
1. Copy the existing `AppIcon-20x20.png` and resize it to all required sizes
2. Run: `sips -z 16 16 AppIcon-20x20.png --out AppIcon-16.png` (repeat for all sizes)
3. Or just use the placeholder generation scripts provided

## Files Changed
- `SharedCore/DesignSystem/Assets.xcassets/AppIcon.appiconset/Contents.json` - Updated with macOS icon slots
- `Scripts/generate_appicons.py` - Python script to generate placeholder icons
- `Scripts/generate_appicons.sh` - Shell script to generate placeholder icons

## Verification
After adding icons, verify:
1. No build warnings about missing AppIcon assets
2. Icon appears correctly in Finder (right-click on app → Get Info)
3. Icon appears in Dock when app is running
4. Icon appears in app switcher (Cmd+Tab)

## Production Deployment
Before releasing to production:
1. Replace placeholder icons with professionally designed icons
2. Ensure all sizes are high quality (not just scaled from one size)
3. Test appearance on both Retina and non-Retina displays
4. Verify icon contrast in both light and dark mode
