#!/usr/bin/env bash
# Build the Android .aar: cargo-ndk cdylib (arm64-v8a) + uniffi Kotlin bindings,
# staged into the roamcore module, then assembled by Gradle.
#
# Prereqs: cargo + rustup target aarch64-linux-android, cargo-ndk, uniffi-bindgen
# (cargo install uniffi --version 0.32.0 --features cli), the Android SDK/NDK,
# and JDK 17. The CI workflow installs all of these.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

JNILIB=android/roamcore/src/main/jniLibs
JAVA=android/roamcore/src/main/java
VERSION=$(grep '^version' Cargo.toml | head -1 | sed 's/version = "\(.*\)"/\1/')

# 1. Host library (bindgen's library mode reads uniffi metadata from it).
cargo build --release

# 2. Android cdylib (arm64-v8a only: that is what modern sideloads run; add
#    ABIs here when the app needs them). iroh's own cdylib targets ride along
#    in jniLibs but our .so is statically linked (NEEDED: libc/libm/libdl only)
#    — drop them, they are ~5 MB of dead weight.
rm -rf "$JNILIB" "$JAVA"
cargo ndk -t arm64-v8a -o "$JNILIB" build --release
find "$JNILIB" -name 'libiroh*.so' -delete

# 3. Kotlin bindings from the HOST library.
uniffi-bindgen generate --library target/release/libgrouse_roam_core.so \
    --language kotlin --out-dir "$JAVA" --no-format

# 3. Assemble the .aar.
cd android
./gradlew --no-daemon :roamcore:assembleRelease
cp roamcore/build/outputs/aar/roamcore-release.aar "../grouse-roam-core-$VERSION.aar"
echo "built grouse-roam-core-$VERSION.aar"
