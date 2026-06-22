#!/bin/bash
# Собирает MRTracker.app — полноценный двойным-кликом запускаемый macOS-бандл.
set -e
cd "$(dirname "$0")"

CONFIG="${1:-release}"
APP="MRTracker.app"
CONTENTS="$APP/Contents"

echo "▸ swift build -c $CONFIG"
swift build -c "$CONFIG"

BIN="$(swift build -c "$CONFIG" --show-bin-path)/MRTracker"

echo "▸ Сборка бандла $APP"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BIN" "$CONTENTS/MacOS/MRTracker"
cp Resources/Info.plist "$CONTENTS/Info.plist"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$CONTENTS/Resources/AppIcon.icns"

# Локальная ad-hoc подпись, чтобы Keychain/сеть работали без вопросов.
codesign --force --deep --sign - "$APP" 2>/dev/null || true

# Опционально: установить в /Applications  →  ./make-app.sh release install
if [ "$2" = "install" ]; then
    echo "▸ Установка в /Applications"
    pkill -f "/Applications/MRTracker.app/Contents/MacOS/MRTracker" 2>/dev/null || true
    rm -rf /Applications/MRTracker.app
    cp -R "$APP" /Applications/MRTracker.app
    codesign --force --deep --sign - /Applications/MRTracker.app 2>/dev/null || true
    echo "✓ Установлено: /Applications/MRTracker.app"
fi

echo "✓ Готово: $(pwd)/$APP"
echo "  Запуск:    open $APP"
echo "  Установка: ./make-app.sh release install"
