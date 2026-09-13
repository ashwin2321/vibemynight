#!/usr/bin/env bash
set -e

echo ==> Setting up Flutter SDK...
if [ -d flutter ]; then
  cd flutter && git pull && cd ..
else
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
fi

export PATH=$PATH:$(pwd)/flutter/bin

flutter doctor -v

echo ==> Building Flutter Web...
cd vibemynight/frontend/flutter_app
flutter pub get
flutter build web --release --no-tree-shake-icons

echo ==> Build complete!
