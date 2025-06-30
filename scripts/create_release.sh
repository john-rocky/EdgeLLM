#!/bin/bash
set -e

echo "🚀 Creating EdgeLLM v0.1.0 Release..."

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUNDLE_FILE="$PROJECT_DIR/dist/EdgeLLM-Bundle.zip"

# Check if bundle exists
if [ ! -f "$BUNDLE_FILE" ]; then
    echo "❌ Error: EdgeLLM-Bundle.zip not found!"
    echo "Please run ./scripts/create_full_xcframework.sh first"
    exit 1
fi

# Create release notes
cat > /tmp/release_notes.md << 'EOF'
## EdgeLLM v0.1.0 - Initial Release

The first release of EdgeLLM - Simple LLM SDK for iOS

### ✨ Features
- **One-line LLM usage**: `EdgeLLM.chat("Hello!")`
- **Supported Models**: Llama 3.2 (3B), Gemma 2 (2B), Phi-3.5 Mini
- **Streaming responses** with AsyncStream support
- **Automatic model management** and caching
- **Metal GPU acceleration** for optimal performance
- **Privacy-first**: Everything runs on-device

### 📦 Installation

#### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/john-rocky/EdgeLLM.git", from: "0.1.0")
]
```

#### Binary Distribution
For pre-built XCFramework, download `EdgeLLM-Bundle.zip` below.
- **Size**: 7.9MB
- **Checksum**: `bc9188ab45b36f6a071cce7e1c9196ccf84c2cdc2dfcd51c33518f10db4ed8e5`

### 🚀 Quick Start
```swift
import EdgeLLM

// Simple one-liner
let response = try await EdgeLLM.chat("Hello, world!")

// With streaming
for try await token in EdgeLLM.stream("Tell me a story") {
    print(token, terminator: "")
}
```

### 📋 Requirements
- iOS 14.0+
- Xcode 15.0+
- ~2GB free space for models

### 📖 Documentation
See the [README](https://github.com/john-rocky/EdgeLLM/blob/main/README.md) for detailed documentation.
EOF

# Create the release
echo "📝 Creating GitHub release..."
gh release create v0.1.0 \
    --title "EdgeLLM v0.1.0 - Initial Release" \
    --notes-file /tmp/release_notes.md \
    --target main

# Upload the bundle
echo "📦 Uploading EdgeLLM-Bundle.zip..."
gh release upload v0.1.0 "$BUNDLE_FILE" \
    --clobber

# Clean up
rm -f /tmp/release_notes.md

echo ""
echo "✅ Release created successfully!"
echo "🔗 View at: https://github.com/john-rocky/EdgeLLM/releases/tag/v0.1.0"
echo ""
echo "📝 Next steps:"
echo "1. Update setup.sh with the actual download URL"
echo "2. Test the binary distribution"
echo "3. Upload model files to Hugging Face"