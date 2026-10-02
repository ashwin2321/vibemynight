#!/usr/bin/env bash
set -e

echo "==> [Vercel Build] Initializing Flutter environment..."
ORIGIN_DIR="$(pwd)"
FLUTTER_DIR="$HOME/flutter"

echo "==> [Vercel Build] Working Directory: $ORIGIN_DIR"

if command -v flutter &> /dev/null; then
  echo "==> Flutter found in system PATH"
elif [ -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "==> Flutter already present at $FLUTTER_DIR"
  export PATH="$FLUTTER_DIR/bin:$PATH"
else
  echo "==> Downloading official Flutter SDK Linux archive from Google CDN..."
  mkdir -p "$HOME"
  curl -sL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz -o /tmp/flutter.tar.xz
  tar -xf /tmp/flutter.tar.xz -C "$HOME"
  rm -f /tmp/flutter.tar.xz
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
git config --global --add safe.directory "*" || true

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
else
  APP_DIR="$ORIGIN_DIR"
fi

echo "==> Building Flutter Web in: $APP_DIR"
cd "$APP_DIR"

flutter pub get
flutter build web --release --no-tree-shake-icons

echo "==> Build complete! Mirroring build/web artifacts..."
if [ -d "$APP_DIR/build/web" ]; then
  mkdir -p "$ORIGIN_DIR/vibemynight/frontend/flutter_app/build"
  cp -rf "$APP_DIR/build/web" "$ORIGIN_DIR/vibemynight/frontend/flutter_app/build/" || true
  mkdir -p "$ORIGIN_DIR/frontend/flutter_app/build"
  cp -rf "$APP_DIR/build/web" "$ORIGIN_DIR/frontend/flutter_app/build/" || true
  mkdir -p "$ORIGIN_DIR/build"
  cp -rf "$APP_DIR/build/web" "$ORIGIN_DIR/build/" || true
fi

cd "$ORIGIN_DIR"
echo "==> [Vercel Build] ALL STEPS COMPLETED SUCCESSFULLY!"
