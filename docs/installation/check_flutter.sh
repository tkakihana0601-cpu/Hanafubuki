#!/bin/bash

# Flutter 準備状況チェック スクリプト

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║      Flutter & プロジェクト 準備状況チェック                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ステップ1: Flutterのチェック
echo "🔍 1. Flutterをチェック中..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version 2>&1 | head -1)
    echo "   ✅ Flutter がインストール済み: $FLUTTER_VERSION"
else
    echo "   ❌ Flutterがインストールされていません"
    echo "   👉 MANUAL_FLUTTER_INSTALL.md を参照してください"
fi
echo ""

# ステップ2: Dartのチェック
echo "🔍 2. Dartをチェック中..."
if command -v dart &> /dev/null; then
    DART_VERSION=$(dart --version 2>&1)
    echo "   ✅ Dart がインストール済み: $DART_VERSION"
else
    echo "   ℹ️  Dart は通常 Flutter に同梱されています"
fi
echo ""

# ステップ3: プロジェクトファイルをチェック
echo "🔍 3. プロジェクトファイルをチェック中..."
if [ -f "pubspec.yaml" ]; then
    echo "   ✅ pubspec.yaml が存在"
else
    echo "   ❌ pubspec.yaml が見つかりません"
fi

if [ -d "lib" ]; then
    DART_FILES=$(find lib -name "*.dart" | wc -l)
    echo "   ✅ Dartファイル: $DART_FILES個"
else
    echo "   ❌ lib ディレクトリが見つかりません"
fi
echo ""

# ステップ4: 依存関係をチェック
echo "🔍 4. 依存関係をチェック中..."
if [ -d "pubspec.lock" ] || [ -f "pubspec.lock" ]; then
    echo "   ✅ pubspec.lock が存在（依存関係がインストール済み）"
else
    echo "   ⏳ pubspec.lock がありません"
    echo "   👉 次のコマンドを実行してください:"
    echo "      flutter pub get"
fi
echo ""

# ステップ5: iOS シミュレータをチェック
echo "🔍 5. iOS シミュレータをチェック中..."
if command -v xcrun &> /dev/null; then
    SIMULATOR_COUNT=$(xcrun simctl list devices | grep -c "iPhone" || echo "0")
    if [ "$SIMULATOR_COUNT" -gt 0 ]; then
        echo "   ✅ iOS シミュレータが使用可能"
    else
        echo "   ⏳ iOS シミュレータが見つかりません"
        echo "   👉 以下のコマンドを実行してください:"
        echo "      open -a Simulator"
    fi
else
    echo "   ❌ Xcode Command Line Tools がインストールされていません"
    echo "   👉 MANUAL_FLUTTER_INSTALL.md を参照してください"
fi
echo ""

# ステップ6: 最終確認
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    準備状況チェック完了                      ║"
echo "├──────────────────────────────────────────────────────────────┤"
echo "║                                                              ║"
echo "║  すべての ✅ が表示されたら、以下を実行してください:        ║"
echo "║                                                              ║"
echo "║    1. flutter pub get                                        ║"
echo "║    2. open -a Simulator                                      ║"
echo "║    3. flutter run                                            ║"
echo "║                                                              ║"
echo "║  ❌ がある場合は、MANUAL_FLUTTER_INSTALL.md を参照          ║"
echo "║                                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
