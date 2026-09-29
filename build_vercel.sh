#!/usr/bin/env bash
set -e

echo "==> Setting up deterministic Flutter SDK environment for Vercel..."

if command -v flutter &> /dev/null; then
  echo "==> Flutter found in environment: $(flutter --version | head -n 1)"
else
  FLUTTER_VERSION="3.24.3-stable"
  FLUTTER_TAR="flutter_linux_${FLUTTER_VERSION}.tar.xz"
  FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_TAR}"

  if [ ! -d "$HOME/flutter/bin" ]; then
    echo "==> Downloading pinned Flutter SDK ($FLUTTER_VERSION)..."
    curl -sSL "$FLUTTER_URL" -o /tmp/flutter.tar.xz
    mkdir -p "$HOME"
    tar -xf /tmp/flutter.tar.xz -C "$HOME"
    rm -f /tmp/flutter.tar.xz
  fi

  export PATH="$PATH:$HOME/flutter/bin"
fi

flutter config --no-analytics
flutter doctor -v

echo "==> Building Flutter Web Application..."
cd vibemynight/frontend/flutter_app
flutter pub get
flutter build web --release --no-tree-shake-icons

echo "==> Vercel Flutter Web build complete: output in vibemynight/frontend/flutter_app/build/web"
