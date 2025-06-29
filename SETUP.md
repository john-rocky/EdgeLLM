# EdgeLLM Setup Guide

## Automatic Setup (Recommended)

EdgeLLM handles all dependencies automatically! Just add it to your project:

```swift
// In Package.swift
dependencies: [
    .package(url: "https://github.com/john-rocky/EdgeLLM", from: "0.1.0")
]
```

## What Happens on First Build

1. **Dependencies Download** (~300MB)
   - MLC runtime libraries
   - Tokenizer libraries
   - Required frameworks

2. **Automatic Configuration**
   - Sets up library paths
   - Configures build settings
   - Links dependencies

## Hosting Your Own Dependencies

If you want to host dependencies yourself:

1. **Build MLC-LLM libraries**:
   ```bash
   git clone https://github.com/mlc-ai/mlc-llm
   cd mlc-llm/ios
   ./prepare_libs.sh
   ```

2. **Package the libraries**:
   ```bash
   tar -czf ios-libs.tar.gz \
       libmlc_llm.a \
       libtvm_runtime.a \
       libsentencepiece.a \
       libtokenizers_cpp.a
   ```

3. **Host on your CDN**:
   - GitHub Releases (up to 2GB)
   - Hugging Face Datasets
   - AWS S3 / Cloudflare R2
   - Any HTTP server

4. **Update setup.sh**:
   ```bash
   # Replace placeholder URL in scripts/setup.sh
   LIBS_URL="https://your-cdn.com/edgellm/libs/v0.1.0/ios-libs.tar.gz"
   ```

## Dependency URLs (Placeholders)

Replace these in `scripts/setup.sh`:

```bash
# Option 1: GitHub Releases
LIBS_URL="https://github.com/yourusername/EdgeLLM/releases/download/v0.1.0/ios-libs.tar.gz"

# Option 2: Hugging Face
LIBS_URL="https://huggingface.co/datasets/yourusername/edgellm-libs/resolve/main/ios-libs.tar.gz"

# Option 3: S3/CDN
LIBS_URL="https://edgellm-libs.s3.amazonaws.com/v0.1.0/ios-libs.tar.gz"
```

## Manual Build (Advanced)

If automatic setup doesn't work:

```bash
# 1. Clone EdgeLLM
git clone https://github.com/john-rocky/EdgeLLM
cd EdgeLLM

# 2. Run setup script
./scripts/setup.sh

# 3. Build with Swift
swift build
```

## Troubleshooting

### "Dependencies not found"
- Run `./scripts/setup.sh` manually
- Check internet connection
- Verify URLs in setup script

### "Library not loaded"
- Ensure all .a files are in `.dependencies/libs/`
- Check library paths in Package.swift

### Build errors
- Minimum iOS 14.0 / macOS 13.0
- Xcode 15.0 or later required
- Swift 5.9 or later

## Size Optimization

To reduce download size:

1. **Use XCFramework** (coming in v0.2.0)
2. **Download only needed architectures**
3. **Use CDN with compression**

## CI/CD Integration

For GitHub Actions:

```yaml
- name: Setup EdgeLLM
  run: |
    git clone https://github.com/john-rocky/EdgeLLM
    cd EdgeLLM
    ./scripts/setup.sh
```