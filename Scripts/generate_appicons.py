#!/usr/bin/env python3
"""
Generate placeholder AppIcon images for macOS Roots app.
Requires: Pillow (PIL)
Install with: pip3 install Pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os

ICON_DIR = "/workspaces/Roots/SharedCore/DesignSystem/Assets.xcassets/AppIcon.appiconset"

# Define all required sizes
SIZES = {
    "AppIcon-16.png": 16,
    "AppIcon-16@2x.png": 32,
    "AppIcon-32.png": 32,
    "AppIcon-32@2x.png": 64,
    "AppIcon-128.png": 128,
    "AppIcon-128@2x.png": 256,
    "AppIcon-256.png": 256,
    "AppIcon-256@2x.png": 512,
    "AppIcon-512.png": 512,
    "AppIcon-512@2x.png": 1024,
}

def create_icon(size, filename):
    """Create a placeholder icon with gradient and 'R' letter"""
    # Create image with gradient background
    img = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(img)
    
    # Draw gradient (simple two-color)
    for y in range(size):
        # Interpolate between two colors
        r = int(74 + (123 - 74) * y / size)
        g = int(144 + (104 - 144) * y / size)
        b = int(226 + (238 - 226) * y / size)
        draw.line([(0, y), (size, y)], fill=(r, g, b))
    
    # Draw rounded rectangle for modern look
    corner_radius = size // 8
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([(0, 0), (size, size)], corner_radius, fill=255)
    
    # Apply rounded corners
    rounded_img = Image.new('RGB', (size, size), (255, 255, 255))
    rounded_img.paste(img, (0, 0))
    
    # Try to add text 'R' if size is large enough
    if size >= 64:
        try:
            font_size = size // 2
            # Try to use a system font, fallback to default if not available
            try:
                font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
            except:
                font = ImageFont.load_default()
            
            text = "R"
            # Get text bounding box
            bbox = draw.textbbox((0, 0), text, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]
            
            # Center the text
            text_x = (size - text_width) // 2
            text_y = (size - text_height) // 2 - font_size // 8
            
            draw = ImageDraw.Draw(rounded_img)
            draw.text((text_x, text_y), text, fill=(255, 255, 255), font=font)
        except Exception as e:
            print(f"Could not add text to icon: {e}")
    
    # Save the icon
    output_path = os.path.join(ICON_DIR, filename)
    rounded_img.save(output_path, 'PNG')
    print(f"Generated: {filename} ({size}x{size})")

def main():
    """Generate all icon sizes"""
    print("Generating AppIcon placeholder images...")
    
    # Check if directory exists
    if not os.path.exists(ICON_DIR):
        print(f"Error: Directory not found: {ICON_DIR}")
        return
    
    # Generate each size
    for filename, size in SIZES.items():
        create_icon(size, filename)
    
    # Remove old iPhone icon if it exists
    old_icon = os.path.join(ICON_DIR, "AppIcon-20x20.png")
    if os.path.exists(old_icon):
        os.remove(old_icon)
        print(f"Removed: AppIcon-20x20.png")
    
    print("\nAppIcon generation complete!")
    print("Note: These are placeholder icons. Replace with professionally designed icons for production.")

if __name__ == "__main__":
    main()
