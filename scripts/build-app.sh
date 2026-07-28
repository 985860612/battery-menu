#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
output_dir="${project_dir}/dist"
app_dir="${output_dir}/Battery Menu.app"

cd "${project_dir}"
swift build -c release --product BatteryMenu

mkdir -p "${app_dir}/Contents/MacOS" "${app_dir}/Contents/Resources"
cp ".build/release/BatteryMenu" "${app_dir}/Contents/MacOS/BatteryMenu"
cp "Support/Info.plist" "${app_dir}/Contents/Info.plist"
cp "Resources/AppIcon.icns" "${app_dir}/Contents/Resources/AppIcon.icns"

codesign --force --deep --sign - "${app_dir}"
echo "${app_dir}"
