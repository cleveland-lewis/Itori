#!/bin/bash

# Model Download Test Server
# Simple HTTP server for testing model downloads locally

echo "════════════════════════════════════════════════════"
echo "  Itori Model Download Test Server"
echo "════════════════════════════════════════════════════"
echo ""

# Configuration
PORT=8000
MODELS_DIR="./test_models"

# Create models directory if it doesn't exist
mkdir -p "$MODELS_DIR"

echo "Setting up test models..."

# Create dummy model files for testing
# macOS Standard: 800MB (we'll create a 10MB dummy for testing)
if [ ! -f "$MODELS_DIR/roots-macos-standard-v1.mlmodel" ]; then
    echo "Creating macOS Standard test model (10MB for testing)..."
    dd if=/dev/urandom of="$MODELS_DIR/roots-macos-standard-v1.mlmodel" bs=1m count=10 2>/dev/null
    echo "✓ macOS model created"
fi

# iOS Lite: 150MB (we'll create a 2MB dummy for testing)
if [ ! -f "$MODELS_DIR/roots-ios-lite-v1.mlmodel" ]; then
    echo "Creating iOS Lite test model (2MB for testing)..."
    dd if=/dev/urandom of="$MODELS_DIR/roots-ios-lite-v1.mlmodel" bs=1m count=2 2>/dev/null
    echo "✓ iOS model created"
fi

echo ""
echo "Test models ready:"
echo "  macOS: $(ls -lh $MODELS_DIR/roots-macos-standard-v1.mlmodel | awk '{print $5}')"
echo "  iOS:   $(ls -lh $MODELS_DIR/roots-ios-lite-v1.mlmodel | awk '{print $5}')"
echo ""
echo "════════════════════════════════════════════════════"
echo "  Starting HTTP server on port $PORT"
echo "════════════════════════════════════════════════════"
echo ""
echo "Model URLs:"
echo "  macOS: http://localhost:$PORT/models/roots-macos-standard-v1.mlmodel"
echo "  iOS:   http://localhost:$PORT/models/roots-ios-lite-v1.mlmodel"
echo ""
echo "To test in Itori app:"
echo "  1. In Xcode, set ModelConfig.useTestingURLs = true"
echo "  2. Run the app"
echo "  3. Go to Settings → AI"
echo "  4. Click Download for macOS or iOS model"
echo ""
echo "Press Ctrl+C to stop the server"
echo "════════════════════════════════════════════════════"
echo ""

# Change to models directory
cd "$MODELS_DIR"

# Start Python HTTP server
if command -v python3 &> /dev/null; then
    python3 -m http.server $PORT
elif command -v python &> /dev/null; then
    python -m SimpleHTTPServer $PORT
else
    echo "Error: Python not found. Please install Python to run this server."
    exit 1
fi
