#!/bin/bash
set -euo pipefail

# EdgeLLM Setup Script
# Automatically downloads and configures all required dependencies

echo "🚀 EdgeLLM Setup Script"
echo "======================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPS_DIR="$PROJECT_DIR/.dependencies"
MLC_DIR="$DEPS_DIR/mlc-llm"

# Create dependencies directory
mkdir -p "$DEPS_DIR"

echo -e "${YELLOW}📥 Checking dependencies...${NC}"

# Function to download file with progress
download_with_progress() {
    local url=$1
    local output=$2
    echo -e "${YELLOW}Downloading: $(basename "$output")${NC}"
    curl -L --progress-bar "$url" -o "$output"
}

# Step 1: Clone or update MLC-LLM
if [ ! -d "$MLC_DIR" ]; then
    echo -e "${YELLOW}📦 Cloning MLC-LLM...${NC}"
    git clone --depth 1 https://github.com/mlc-ai/mlc-llm.git "$MLC_DIR"
else
    echo -e "${GREEN}✓ MLC-LLM already exists${NC}"
fi

# Step 2: Download pre-built libraries
LIBS_DIR="$DEPS_DIR/libs"
mkdir -p "$LIBS_DIR"

# Check if libraries already exist
if [ ! -f "$LIBS_DIR/.download_complete" ]; then
    echo -e "${YELLOW}📥 Downloading pre-built libraries...${NC}"
    
    # PLACEHOLDER: Replace with actual URLs when hosting libraries
    LIBS_URL="https://your-cdn.com/edgellm/libs/v0.1.0/ios-libs.tar.gz"
    LIBS_CHECKSUM="PLACEHOLDER_CHECKSUM"
    
    # Alternative hosting options (uncomment one):
    # LIBS_URL="https://github.com/yourusername/EdgeLLM/releases/download/v0.1.0/ios-libs.tar.gz"
    # LIBS_URL="https://edgellm-libs.s3.amazonaws.com/v0.1.0/ios-libs.tar.gz"
    # LIBS_URL="https://huggingface.co/datasets/yourusername/edgellm-libs/resolve/main/ios-libs.tar.gz"
    
    if [[ "$LIBS_URL" == *"PLACEHOLDER"* ]] || [[ "$LIBS_URL" == *"your-cdn"* ]]; then
        echo -e "${RED}❌ Error: Library URLs are not configured yet${NC}"
        echo -e "${YELLOW}📋 For now, you need to build libraries manually:${NC}"
        echo ""
        echo "  cd $MLC_DIR/ios"
        echo "  ./prepare_libs.sh"
        echo ""
        echo -e "${YELLOW}Or download pre-built libraries from:${NC}"
        echo "  https://github.com/john-rocky/EdgeLLM/releases"
        echo ""
        exit 1
    fi
    
    # Download libraries
    TEMP_FILE="$LIBS_DIR/temp_libs.tar.gz"
    download_with_progress "$LIBS_URL" "$TEMP_FILE"
    
    # Verify checksum (optional)
    if [[ "$LIBS_CHECKSUM" != "PLACEHOLDER_CHECKSUM" ]]; then
        echo -e "${YELLOW}🔐 Verifying checksum...${NC}"
        ACTUAL_CHECKSUM=$(shasum -a 256 "$TEMP_FILE" | cut -d' ' -f1)
        if [[ "$ACTUAL_CHECKSUM" != "$LIBS_CHECKSUM" ]]; then
            echo -e "${RED}❌ Checksum mismatch!${NC}"
            rm -f "$TEMP_FILE"
            exit 1
        fi
    fi
    
    # Extract libraries
    echo -e "${YELLOW}📦 Extracting libraries...${NC}"
    tar -xzf "$TEMP_FILE" -C "$LIBS_DIR"
    rm -f "$TEMP_FILE"
    
    # Mark download as complete
    touch "$LIBS_DIR/.download_complete"
    echo -e "${GREEN}✓ Libraries downloaded successfully${NC}"
else
    echo -e "${GREEN}✓ Libraries already downloaded${NC}"
fi

# Step 3: Create symbolic links for Package.swift
echo -e "${YELLOW}🔗 Setting up symbolic links...${NC}"

# Link to MLCSwift
if [ ! -L "$PROJECT_DIR/../ios/MLCSwift" ]; then
    mkdir -p "$PROJECT_DIR/../ios"
    ln -sf "$MLC_DIR/ios/MLCSwift" "$PROJECT_DIR/../ios/MLCSwift"
fi

# Link libraries to build directory
if [ ! -L "$PROJECT_DIR/../build" ]; then
    ln -sf "$LIBS_DIR" "$PROJECT_DIR/../build"
fi

# Step 4: Download a sample model (optional)
MODELS_DIR="$DEPS_DIR/models"
mkdir -p "$MODELS_DIR"

if [ ! -f "$MODELS_DIR/.model_downloaded" ] && [ "${DOWNLOAD_MODEL:-false}" == "true" ]; then
    echo -e "${YELLOW}📥 Downloading sample model...${NC}"
    
    # PLACEHOLDER: Replace with actual model URL
    MODEL_URL="https://huggingface.co/mlc-ai/Llama-3.2-3B-Instruct-q4f16_1-MLC/resolve/main/model.tar.gz"
    
    # Download and extract model
    # ... (similar to libraries)
    
    touch "$MODELS_DIR/.model_downloaded"
fi

# Step 5: Verify setup
echo -e "${YELLOW}🔍 Verifying setup...${NC}"

# Check if all required files exist
REQUIRED_LIBS=(
    "libmlc_llm.a"
    "libtvm_runtime.a"
    "libsentencepiece.a"
    "libtokenizers_cpp.a"
)

ALL_GOOD=true
for lib in "${REQUIRED_LIBS[@]}"; do
    if [ ! -f "$LIBS_DIR/$lib" ]; then
        echo -e "${RED}❌ Missing: $lib${NC}"
        ALL_GOOD=false
    else
        echo -e "${GREEN}✓ Found: $lib${NC}"
    fi
done

if [ "$ALL_GOOD" = true ]; then
    echo ""
    echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
    echo ""
    echo "You can now use EdgeLLM in your project:"
    echo ""
    echo "  import EdgeLLM"
    echo "  let response = try await EdgeLLM.chat(\"Hello!\")"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Setup incomplete. Some libraries are missing.${NC}"
    echo "Please check the errors above."
    exit 1
fi