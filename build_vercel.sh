#!/usr/bin/env bash
set -e

echo "==> Setting up Flutter PATH..."
if [ -d "$(pwd)/flutter/bin" ]; then
  export PATH="$PATH:$(pwd)/flutter/bin"
elif [ -d "$HOME/flutter/bin" ]; then
  export PATH="$PATH:$HOME/flutter/bin"
fi

flutter --version

echo "==> Building Flutter Web Application..."
cd vibemynight/frontend/flutter_app
flutter pub get
flutter build web --release --no-tree-shake-icons

echo "==> Build complete: output in vibemynight/frontend/flutter_app/build/web"
