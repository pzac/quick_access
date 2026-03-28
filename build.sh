#!/bin/bash
set -e

APP_NAME="Quick Access"
BUNDLE="${APP_NAME}.app"
SOURCES="QuickAccess/QuickAccessApp.swift QuickAccess/FavoritesManager.swift"

echo "Building ${APP_NAME}..."

swiftc -swift-version 5 -o QuickAccess_bin -framework SwiftUI -framework AppKit $SOURCES

mkdir -p "${BUNDLE}/Contents/MacOS" "${BUNDLE}/Contents/Resources"
mv QuickAccess_bin "${BUNDLE}/Contents/MacOS/QuickAccess"
cp QuickAccess/Info.plist "${BUNDLE}/Contents/Info.plist"
cp QuickAccess/AppIcon.icns "${BUNDLE}/Contents/Resources/AppIcon.icns"

echo "Built ${BUNDLE} successfully."
echo "Run with: open \"${BUNDLE}\""
