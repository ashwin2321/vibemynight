#!/usr/bin/env bash
set -e

echo "==> [Vercel Build] Initializing build environment..."
git config --global --add safe.directory "*" || true

ROOT_DIR="$(pwd)"
FLUTTER_DIR="$HOME/flutter"

if command -v flutter &> /dev/null; then
  echo "==> Flutter found in system PATH"
elif [ -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "==> Flutter found in $FLUTTER_DIR"
  export PATH="$PATH:$FLUTTER_DIR/bin"
elif [ -x "$ROOT_DIR/flutter/bin/flutter" ]; then
  echo "==> Flutter found in $ROOT_DIR/flutter"
  export PATH="$PATH:$ROOT_DIR/flutter/bin"
else
  echo "==> Downloading Flutter SDK stable..."
  rm -rf "$FLUTTER_DIR" "$ROOT_DIR/flutter" || true
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
  export PATH="$PATH:$FLUTTER_DIR/bin"
fi

git config --global --add safe.directory "$FLUTTER_DIR" || true
git config --global --add safe.directory "$ROOT_DIR/flutter" || true

flutter --version

echo "==> [Vercel Build] Locating Flutter App..."
if [ -d "$ROOT_DIR/vibemynight/frontend/flutter_app" ]; then
  cd "$ROOT_DIR/vibemynight/frontend/flutter_app"
elif [ -d "$ROOT_DIR/frontend/flutter_app" ]; then
  cd "$ROOT_DIR/frontend/flutter_app"
else
  cd "$ROOT_DIR"
fi

echo "==> Current Directory: $(pwd)"
flutter pub get
flutter build web --release --no-tree-shake-icons

# Ensure build artifacts exist at all candidate output locations
if [ -d "build/web" ] && [ "$ROOT_DIR" != "$(pwd)" ]; then
  echo "==> Copying build output to root directories..."
  mkdir -p "$ROOT_DIR/vibemynight/frontend/flutter_app/build"
  cp -r build/web "$ROOT_DIR/vibemynight/frontend/flutter_app/build/" || true
  mkdir -p "$ROOT_DIR/frontend/flutter_app/build"
  cp -r build/web "$ROOT_DIR/frontend/flutter_app/build/" || true
fi

cd "$ROOT_DIR"
echo "==> [Vercel Build] Complete!"
