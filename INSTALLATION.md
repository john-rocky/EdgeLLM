# EdgeLLM Installation Guide

## 🚀 Simplest Installation (Recommended)

Just add EdgeLLM to your Xcode project:

1. **File → Add Package Dependencies**
2. **Enter**: `https://github.com/john-rocky/EdgeLLM`
3. **Click**: Add Package

That's it! EdgeLLM will handle everything else automatically.

## 📱 First Run

When you first use EdgeLLM:

```swift
import EdgeLLM

// First time: Downloads runtime (~300MB)
let response = try await EdgeLLM.chat("Hello!")
```

The first run will:
1. Download required runtime libraries
2. Cache them locally
3. Initialize the LLM engine

**Note**: First run requires internet connection and may take 2-3 minutes.

## 🔧 Manual Installation (Advanced)

If automatic installation fails:

```bash
# Clone the repository
git clone https://github.com/john-rocky/EdgeLLM
cd EdgeLLM

# Run setup script
./scripts/setup.sh

# Build
swift build
```

## 💾 Offline Installation

For environments without internet access:

1. Download the runtime package from [Releases](https://github.com/john-rocky/EdgeLLM/releases)
2. Place in: `~/Library/Application Support/EdgeLLM/`
3. Use EdgeLLM normally

## 🏢 Enterprise Setup

For corporate environments with restrictions:

1. Host the runtime on your internal server
2. Set environment variable:
   ```bash
   export EDGELLM_RUNTIME_URL="https://internal.company.com/edgellm/runtime.zip"
   ```
3. EdgeLLM will download from your server

## ❓ Troubleshooting

### "Failed to download runtime"
- Check internet connection
- Verify firewall settings
- Try manual installation

### "Module 'EdgeLLM' not found"
- Clean build folder (Cmd+Shift+K)
- Reset package caches: File → Packages → Reset Package Caches

### Large app size
- Runtime is cached separately from your app
- Only downloaded once per device
- Shared between all apps using EdgeLLM

## 📊 Storage Requirements

- **Runtime Download**: ~300MB
- **Installed Size**: ~500MB
- **Model Cache**: 2-4GB per model
- **Total**: ~5GB for full setup

## 🔄 Updates

EdgeLLM automatically checks for updates. To force update:

```swift
try await EdgeLLM.updateRuntime()
```