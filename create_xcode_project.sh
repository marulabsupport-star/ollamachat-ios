#!/bin/bash
# create_xcode_project.sh
# Creates an Xcode project for OllamaChat using swift-package-manager + xcodeproj generation
# Run this after opening the project in Xcode

set -e

PROJECT_DIR="/Users/jasonkim/.openclaw/workspace/OllamaChat-iOS"
cd "$PROJECT_DIR"

echo "🔧 Creating Xcode project for OllamaChat..."

# Check if xcodeproj already exists
if [ -d "OllamaChat.xcodeproj" ]; then
    echo "✅ xcodeproj already exists. Opening..."
    open OllamaChat.xcodeproj
    exit 0
fi

# Generate xcodeproj from Package.swift
echo "📦 Generating xcodeproj from Package.swift..."
swift package generate-xcodeproj 2>/dev/null || true

# If generate-xcodeproj doesn't work (it's deprecated), create manually
echo ""
echo "⚠️  Automatic xcodeproj generation may not work for iOS projects."
echo ""
echo "📋 Manual steps to create the project:"
echo ""
echo "1. Open Xcode"
echo "2. File → New → Project → App"
echo "3. Product Name: OllamaChat"
echo "4. Organization Identifier: com.openclaw"
echo "5. Interface: SwiftUI"
echo "6. Storage: SwiftData"
echo "7. Minimum Deployment: iOS 17.0"
echo "8. Save to: $PROJECT_DIR (overwrite existing files)"
echo ""
echo "Then add all Swift files from OllamaChat/ subdirectories to the project."
echo ""
echo "📋 File list to add:"
find OllamaChat -name "*.swift" | sort
echo ""
echo "🎯 Key configuration:"
echo "  - Bundle ID: com.openclaw.ollamachat"
echo "  - Deployment Target: iOS 17.0"
echo "  - Info.plist: Add NSLocalNetworkUsageDescription"
echo "  - Info.plist: Add NSAppTransportSecurity → NSAllowsArbitraryLoads = YES"
echo "  - Capabilities: Keychain Sharing"
echo ""
echo "✅ Swift source files are ready at:"
echo "  $PROJECT_DIR/OllamaChat/"