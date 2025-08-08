#!/bin/bash

# ReceiptLock Build Script
# This script helps build and test the ReceiptLock iOS app

set -e

echo "🚀 ReceiptLock Build Script"
echo "=========================="

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed or not in PATH"
    echo "Please install Xcode from the App Store"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "ReceiptLock.xcodeproj/project.pbxproj" ]; then
    echo "❌ Please run this script from the ReceiptLock project directory"
    exit 1
fi

echo "✅ Xcode found"
echo "✅ Project structure verified"

# Clean build
echo "🧹 Cleaning previous builds..."
xcodebuild clean -project ReceiptLock.xcodeproj -scheme ReceiptLock

# Build for simulator
echo "🔨 Building for iOS Simulator..."
xcodebuild build -project ReceiptLock.xcodeproj -scheme ReceiptLock -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed!"
    exit 1
fi

# Run unit tests
echo "🧪 Running unit tests..."
xcodebuild test -project ReceiptLock.xcodeproj -scheme ReceiptLock -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' -only-testing:ReceiptLockTests

if [ $? -eq 0 ]; then
    echo "✅ Unit tests passed!"
else
    echo "❌ Unit tests failed!"
    exit 1
fi

echo ""
echo "🎉 All checks passed! The app is ready to run."
echo ""
echo "To run the app:"
echo "1. Open ReceiptLock.xcodeproj in Xcode"
echo "2. Select your target device/simulator"
echo "3. Press Cmd+R to build and run"
echo ""
echo "To run tests manually:"
echo "- Press Cmd+U in Xcode to run all tests"
echo "- Press Cmd+Shift+U to run UI tests" 