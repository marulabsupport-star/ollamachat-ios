#!/bin/bash
# setup_xcode_project.sh
# Prepares all files for Xcode project creation
# Run `./setup_xcode_project.sh` then open Xcode to create the project

set -e

PROJECT_DIR="/Users/jasonkim/.openclaw/workspace/OllamaChat-iOS"
cd "$PROJECT_DIR"

echo "🔧 OllamaChat iOS - Xcode Project Setup"
echo "========================================"
echo ""

# 1. Verify all Swift files exist
echo "📋 Checking Swift files..."
SWIFT_FILES=$(find OllamaChat -name "*.swift" | sort)
FILE_COUNT=$(echo "$SWIFT_FILES" | wc -l | tr -d ' ')
echo "   Found $FILE_COUNT Swift files"

for f in $SWIFT_FILES; do
    if [ ! -f "$f" ]; then
        echo "   ❌ Missing: $f"
    fi
done

echo ""

# 2. Check for known platform issues
echo "🔍 Checking platform compatibility..."
ISSUES=0

# Check for systemGray6 (iOS only, not macOS)
GRAY6=$(grep -rn "systemGray6" OllamaChat/ --include="*.swift" 2>/dev/null || true)
if [ -n "$GRAY6" ]; then
    echo "   ⚠️  systemGray6 found (iOS only):"
    echo "$GRAY6"
    ISSUES=$((ISSUES + 1))
fi

# Check for PhotosPickerItem without iOS guard
PHOTO=$(grep -rn "PhotosPickerItem" OllamaChat/ --include="*.swift" | grep -v "#if os(iOS)" | grep -v "^.*#if" 2>/dev/null || true)
if [ -n "$PHOTO" ]; then
    echo "   ℹ️  PhotosPickerItem usage (iOS only - guarded with #if os(iOS)):"
    echo "$PHOTO"
fi

# Check for navigationBarTitleDisplayMode without iOS guard
NAVTITLE=$(grep -rn "navigationBarTitleDisplayMode" OllamaChat/ --include="*.swift" | grep -v "#if os(iOS)" 2>/dev/null || true)
if [ -n "$NAVTITLE" ]; then
    echo "   ℹ️  navigationBarTitleDisplayMode (iOS only - guarded with #if os(iOS)):"
    echo "$NAVTITLE"
fi

if [ $ISSUES -eq 0 ]; then
    echo "   ✅ No blocking issues found"
fi

echo ""

# 3. List all source files by group
echo "📁 Source file groups for Xcode:"
echo ""
for dir in Models Config Repositories Runtime Services ViewModels Views/App Views/Components Theme; do
    FULL_DIR="OllamaChat/$dir"
    if [ -d "$FULL_DIR" ]; then
        FILES=$(find "$FULL_DIR" -name "*.swift" -exec basename {} \; | sort)
        COUNT=$(echo "$FILES" | wc -l | tr -d ' ')
        echo "   📂 $dir/ ($COUNT files)"
        for f in $FILES; do
            echo "      - $f"
        done
    fi
done

# App files
echo "   📂 App/"
echo "      - OllamaChatApp.swift"
echo "      - ContentView.swift"

echo ""

# 4. Print Xcode setup instructions
echo "🎯 Xcode Project Creation Steps"
echo "================================"
echo ""
echo "1. Open Xcode"
echo "2. File → New → Project → App"
echo "3. Product Name: OllamaChat"
echo "4. Team: Select your team"
echo "5. Organization Identifier: com.openclaw"
echo "6. Interface: SwiftUI"
echo "7. Language: Swift"
echo "8. Storage: SwiftData (NOT Core Data)"
echo "9. Include Tests: Yes"
echo "10. Save to: $PROJECT_DIR (choose a DIFFERENT folder first, then move files)"
echo ""
echo "   OR: Save directly to $PROJECT_DIR and let Xcode create its own files,"
echo "   then replace the generated files with our source files."
echo ""
echo "11. After project creation, add all Swift files:"
echo "    - Remove the default ContentView.swift and OllamaChatApp.swift"
echo "    - Add all files from OllamaChat/ subdirectories"
echo "    - Create groups matching the directory structure"
echo ""
echo "12. Project Settings:"
echo "    - Bundle Identifier: com.openclaw.ollamachat"
echo "    - Minimum Deployment: iOS 17.0"
echo "    - Swift Language Version: 5"
echo ""
echo "13. Info.plist additions (in Project → Info → Custom iOS Target Properties):"
echo "    - NSLocalNetworkUsageDescription = 'Ollama Chat needs local network access to connect to Ollama servers'"
echo "    - NSAppTransportSecurity → NSAllowsArbitraryLoads = YES (for local HTTP)"
echo ""
echo "14. Capabilities:"
echo "    - Keychain Sharing (for API key storage)"
echo ""
echo "15. Build and fix any remaining compilation errors"
echo ""
echo "✅ Setup check complete!"