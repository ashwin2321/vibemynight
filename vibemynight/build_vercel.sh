#!/usr/bin/env bash
set -e

echo "==> [Vercel Build] Setting up Flutter SDK..."

if command -v flutter &> /dev/null; then
  echo "==> Flutter found in PATH: $(flutter --version | head -n 1)"
elif [ -d "$HOME/flutter/bin" ]; then
  export PATH="$PATH:$HOME/flutter/bin"
elif [ -d "$(pwd)/flutter/bin" ]; then
  export PATH="$PATH:$(pwd)/flutter/bin"
else
  echo "==> Downloading Flutter SDK stable..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
  export PATH="$PATH:$(pwd)/flutter/bin"
fi

flutter --version

echo "==> [Vercel Build] Building Flutter Web..."
if [ -d "vibemynight/frontend/flutter_app" ]; then
  cd vibemynight/frontend/flutter_app
elif [ -d "frontend/flutter_app" ]; then
  cd frontend/flutter_app
fi

flutter pub get
flutter build web --release --no-tree-shake-icons

echo "==> [Vercel Build] Complete!"
