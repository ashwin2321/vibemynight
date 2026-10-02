#!/usr/bin/env bash
set -e

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
elif [ -x "$ORIGIN_DIR/flutter/bin/flutter" ]; then
  echo "==> Flutter found in $ORIGIN_DIR/flutter"
  export PATH="$ORIGIN_DIR/flutter/bin:$PATH"
else
  echo "==> Downloading Flutter SDK stable..."
  rm -rf "$FLUTTER_DIR" "$ORIGIN_DIR/flutter" || true
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

git config --global --add safe.directory "$FLUTTER_DIR" || true
git config --global --add safe.directory "$ORIGIN_DIR/flutter" || true

flutter config --no-analytics
flutter --version

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
  echo "==> Output directory $APP_DIR/build/web has $(ls "$APP_DIR/build/web" | wc -l) files."
  # Mirror to both possible Vercel output directories
  mkdir -p "$ORIGIN_DIR/vibemynight/frontend/flutter_app/build"
  cp -r "$APP_DIR/build/web" "$ORIGIN_DIR/vibemynight/frontend/flutter_app/build/" || true
  mkdir -p "$ORIGIN_DIR/frontend/flutter_app/build"
  cp -r "$APP_DIR/build/web" "$ORIGIN_DIR/frontend/flutter_app/build/" || true
fi

cd "$ORIGIN_DIR"
echo "==> [Vercel Build] All steps completed successfully!"
