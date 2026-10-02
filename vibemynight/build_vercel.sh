#!/usr/bin/env bash

echo "==> [Vercel Build] Initializing build environment..."
git config --global --add safe.directory "*" || true

ORIGIN_DIR="$(pwd)"
FLUTTER_DIR="$HOME/flutter"

echo "==> [Vercel Build] Current working directory: $ORIGIN_DIR"

if command -v flutter &> /dev/null; then
  echo "==> Flutter found in system PATH"
elif [ -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "==> Flutter found in $FLUTTER_DIR"
  export PATH="$FLUTTER_DIR/bin:$PATH"
else
  echo "==> Downloading Flutter SDK stable..."
  rm -rf "$FLUTTER_DIR" "$ORIGIN_DIR/flutter" || true
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR" || git clone -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
git config --global --add safe.directory "$FLUTTER_DIR" || true
git config --global --add safe.directory "$ORIGIN_DIR" || true

flutter --version || true

echo "==> [Vercel Build] Locating Flutter App directory..."
APP_DIR=""
if [ -f "$ORIGIN_DIR/pubspec.yaml" ]; then
  APP_DIR="$ORIGIN_DIR"
elif [ -d "$ORIGIN_DIR/vibemynight/frontend/flutter_app" ]; then
  APP_DIR="$ORIGIN_DIR/vibemynight/frontend/flutter_app"
elif [ -d "$ORIGIN_DIR/frontend/flutter_app" ]; then
  APP_DIR="$ORIGIN_DIR/frontend/flutter_app"
elif [ -d "frontend/flutter_app" ]; then
  APP_DIR="$(pwd)/frontend/flutter_app"
else
  APP_DIR="$ORIGIN_DIR"
fi

echo "==> Building Flutter Web in: $APP_DIR"
cd "$APP_DIR"

flutter pub get
flutter build web --release --no-tree-shake-icons

echo "==> Build successful! Syncing output directories..."
if [ -d "$APP_DIR/build/web" ]; then
  echo "==> Found build output in $APP_DIR/build/web"
  mkdir -p "$ORIGIN_DIR/vibemynight/frontend/flutter_app/build"
  cp -rf "$APP_DIR/build/web" "$ORIGIN_DIR/vibemynight/frontend/flutter_app/build/" || true
  mkdir -p "$ORIGIN_DIR/frontend/flutter_app/build"
  cp -rf "$APP_DIR/build/web" "$ORIGIN_DIR/frontend/flutter_app/build/" || true
  mkdir -p "$ORIGIN_DIR/build"
  cp -rf "$APP_DIR/build/web" "$ORIGIN_DIR/build/" || true
fi

cd "$ORIGIN_DIR"
echo "==> [Vercel Build] All steps completed successfully!"
