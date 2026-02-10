#!/bin/bash

# Flutter インストール スクリプト（macOS）

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║     Flutter & Dart インストール スクリプト                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ステップ1: Homebrewの確認
echo "📦 ステップ1: Homebrewを確認中..."
if command -v brew &> /dev/null; then
    echo "✅ Homebrewはインストール済みです"
    brew --version
else
    echo "⏳ Homebrewをインストール中... (これには5-10分かかる場合があります)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" << 'EOF'

EOF
    
    # Pathを設定
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
    
    echo "✅ Homebrewをインストールしました"
fi

echo ""

# ステップ2: Flutterのインストール
echo "🚀 ステップ2: Flutterをインストール中..."
if command -v flutter &> /dev/null; then
    echo "✅ Flutterはインストール済みです"
    flutter --version
else
    echo "⏳ Flutterをインストール中..."
    brew install flutter
    echo "✅ Flutterをインストールしました"
fi

echo ""

# ステップ3: Pathの設定
echo "🔧 ステップ3: Pathを確認中..."
if grep -q 'flutter/bin' ~/.zprofile; then
    echo "✅ PathにFlutterが登録済みです"
else
    echo "設定中..."
    echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zprofile
    source ~/.zprofile
fi

echo ""

# ステップ4: 診断を実行
echo "🔍 ステップ4: Flutter診断を実行中..."
echo ""
flutter doctor

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                  ✅ インストール完了！                   ║"
echo "├────────────────────────────────────────────────────────────┤"
echo "║                                                            ║"
echo "║  次のコマンドでアプリを実行してください:                  ║"
echo "║                                                            ║"
echo "║    cd /Users/tomoki/Desktop/flutter_app                   ║"
echo "║    flutter pub get                                         ║"
echo "║    open -a Simulator                                       ║"
echo "║    flutter run                                             ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
