#!/bin/bash
set -e

# Android AAB
flutter build appbundle --release --obfuscate --split-debug-info=out/and/debug-info

mkdir -p out/and
cp build/app/outputs/bundle/release/app-release.aab out/and/

# iOS IPA
flutter build ipa --release --obfuscate --split-debug-info=out/ios/debug-info

mkdir -p out/ios
cp build/ios/ipa/Runner.ipa out/ios/