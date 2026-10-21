#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
cd "$project_dir"

swift build --disable-sandbox

app_dir="$project_dir/dist/Beauty-R1 Keymap.app"
mkdir -p "$app_dir/Contents/MacOS"
cp "$project_dir/.build/debug/BeautyR1App" "$app_dir/Contents/MacOS/BeautyR1App"

cat > "$app_dir/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Beauty-R1 Keymap</string>
    <key>CFBundleDisplayName</key><string>Beauty-R1 按鍵設定</string>
    <key>CFBundleIdentifier</key><string>org.tern.beautyr1keymap</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleShortVersionString</key><string>1.0.0</string>
    <key>CFBundleExecutable</key><string>BeautyR1App</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSInputMonitoringUsageDescription</key><string>讀取 Beauty-R1 遙控器的按鍵事件，顯示在按鍵測試區。</string>
</dict>
</plist>
PLIST

codesign --force --sign - "$app_dir"
echo "$app_dir"
