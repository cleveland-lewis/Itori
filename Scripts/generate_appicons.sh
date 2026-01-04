#!/bin/bash
# Script to generate placeholder AppIcon images for macOS
# This creates simple colored squares as placeholders until proper icons are designed

ICON_DIR="/workspaces/Itori/SharedCore/DesignSystem/Assets.xcassets/AppIcon.appiconset"

# Check if we have ImageMagick or sips (macOS built-in)
if command -v sips &> /dev/null; then
    TOOL="sips"
elif command -v convert &> /dev/null; then
    TOOL="imagemagick"
else
    echo "Error: Neither sips nor ImageMagick found. Install ImageMagick with: apt-get install imagemagick"
    exit 1
fi

# Create a base 1024x1024 icon
if [ "$TOOL" = "imagemagick" ]; then
    # Create a gradient icon with ImageMagick
    convert -size 1024x1024 \
        -define gradient:angle=135 \
        gradient:'#4A90E2'-'#7B68EE' \
        -gravity center \
        -pointsize 400 \
        -fill white \
        -annotate +0+0 "R" \
        "$ICON_DIR/base-1024.png"
else
    # For sips, we need an existing image - just note that manual creation is needed
    echo "Using macOS sips - please provide a base 1024x1024 icon first"
    exit 1
fi

# Generate all required sizes
declare -A sizes=(
    ["AppIcon-16.png"]="16"
    ["AppIcon-16@2x.png"]="32"
    ["AppIcon-32.png"]="32"
    ["AppIcon-32@2x.png"]="64"
    ["AppIcon-128.png"]="128"
    ["AppIcon-128@2x.png"]="256"
    ["AppIcon-256.png"]="256"
    ["AppIcon-256@2x.png"]="512"
    ["AppIcon-512.png"]="512"
    ["AppIcon-512@2x.png"]="1024"
)

for filename in "${!sizes[@]}"; do
    size="${sizes[$filename]}"
    if [ "$TOOL" = "imagemagick" ]; then
        convert "$ICON_DIR/base-1024.png" -resize "${size}x${size}" "$ICON_DIR/$filename"
    else
        sips -z "$size" "$size" "$ICON_DIR/base-1024.png" --out "$ICON_DIR/$filename"
    fi
    echo "Generated: $filename (${size}x${size})"
done

# Remove the old iPhone icon
rm -f "$ICON_DIR/AppIcon-20x20.png"

echo "AppIcon generation complete!"
echo "Note: These are placeholder icons. Replace with professionally designed icons for production."
