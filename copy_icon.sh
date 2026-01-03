#!/bin/bash

# Copy itori.icon to project root and rename to Itori.icon

echo "Copying and renaming icon file..."
cp /Users/clevelandlewis/Desktop/Itori/Docs/itori.icon /Users/clevelandlewis/Desktop/Itori/Itori.icon

if [ -f "/Users/clevelandlewis/Desktop/Itori/Itori.icon" ]; then
    echo "✅ Success! Itori.icon has been created in the project root."
    ls -lh /Users/clevelandlewis/Desktop/Itori/Itori.icon
else
    echo "❌ Error: Failed to create Itori.icon"
    exit 1
fi
