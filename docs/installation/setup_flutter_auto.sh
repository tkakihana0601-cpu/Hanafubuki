#!/bin/bash

# Flutter インストール - ダウンロード & セットアップスクリプト

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Flutter SDK セットアップ スクリプト                     ║"
echo "║                                                            ║"
echo "║   このスクリプトは以下を実行します：                      ║"
echo "║   1. ~/development フォルダを作成                         ║"
echo "║   2. Flutter SDKをダウンロード & 解凍                     ║"
echo "║   3. Pathを設定                                           ║"
echo "║   4. flutter doctor を実行                                ║"
echo "║   5. flutter pub get を実行                               ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ステップ1: 作業フォルダを準備
echo "📁 ステップ1: 作業フォルダを準備中..."
mkdir -p ~/development
cd ~/development
echo "✅ ~/development を作成"
echo ""

# ステップ2: Flutter SDKをダウンロード
echo "📥 ステップ2: Flutter SDKをダウンロード中..."
echo "   (これには2-5分かかります)"
echo ""

# ダウンロードURLを定義
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.24.0.zip"

# ダウンロード試行
echo "   URL: $FLUTTER_URL"
echo ""

if command -v wget &> /dev/null; then
    echo "   wget を使用してダウンロード中..."
    wget -q --show-progress -O flutter_sdk.zip "$FLUTTER_URL"
elif command -v curl &> /dev/null; then
    echo "   curl を使用してダウンロード中..."
    curl -# -L -o flutter_sdk.zip "$FLUTTER_URL"
else
    echo "❌ エラー: wget または curl がありません"
    echo "   以下のURL から手動でダウンロードしてください："
    echo "   $FLUTTER_URL"
    echo ""
    echo "   ダウンロード後、~/development に移動して以下を実行："
    echo "   unzip flutter_macos_arm64_3.24.0.zip"
    exit 1
fi

echo ""
echo "✅ ダウンロード完了"
echo ""

# ステップ3: 解凍
echo "📦 ステップ3: SDK を解凍中..."
unzip -q flutter_sdk.zip
echo "✅ 解凍完了"
rm -f flutter_sdk.zip
echo ""

# ステップ4: Pathを設定
echo "🔧 ステップ4: Pathを設定中..."

# ~/.zprofile にPathを追加
if grep -q 'flutter/bin' ~/.zprofile 2>/dev/null; then
    echo "✅ Pathは既に登録済みです"
else
    echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zprofile
    echo "✅ ~/.zprofile に追加しました"
fi

# 現在のセッションに反映
export PATH="$PATH:$HOME/development/flutter/bin"
source ~/.zprofile 2>/dev/null || true

echo ""

# ステップ5: Flutter を初期化
echo "🚀 ステップ5: Flutter を初期化中..."
$HOME/development/flutter/bin/flutter config --no-analytics
echo "✅ Flutter を初期化しました"
echo ""

# ステップ6: 診断を実行
echo "🔍 ステップ6: 診断を実行中..."
echo ""
$HOME/development/flutter/bin/flutter doctor
echo ""

# ステップ7: プロジェクトを準備
echo "📦 ステップ7: プロジェクトの依存関係をインストール中..."
cd /Users/tomoki/Desktop/flutter_app
$HOME/development/flutter/bin/flutter pub get
echo "✅ 依存関係をインストールしました"
echo ""

# 完了
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              ✅ セットアップ完了！                        ║"
echo "├────────────────────────────────────────────────────────────┤"
echo "║                                                            ║"
echo "║  次のコマンドでアプリを実行してください:                  ║"
echo "║                                                            ║"
echo "║    1. open -a Simulator                                   ║"
echo "║    2. cd /Users/tomoki/Desktop/flutter_app                ║"
echo "║    3. flutter run                                          ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
