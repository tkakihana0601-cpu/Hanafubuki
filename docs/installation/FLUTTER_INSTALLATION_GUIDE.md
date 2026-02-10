# 🚀 Flutter インストール＆セットアップ - 統合ガイド

**プロジェクト**: Flutter 将棋ゲーム  
**対象**: macOS (Apple Silicon)  
**バージョン**: Flutter 3.38.9 (stable channel)  
**総セットアップ時間**: 約10-15分

---

## 📋 目次

1. [概要＆前提条件](#概要前提条件)
2. [方法A：Homebrew を使用（推奨・最速）](#方法ahomebrew-を使用推奨最速)
3. [方法B：手動インストール（sudo不可の場合）](#方法b手動インストールsudo不可の場合)
4. [セットアップ確認](#セットアップ確認)
5. [プロジェクト初期化](#プロジェクト初期化)
6. [アプリ実行](#アプリ実行)
7. [トラブルシューティング](#トラブルシューティング)

---

## 概要&前提条件

### 📦 準備確認

- **macOS バージョン**: 11.0 以上推奨
- **Xcode コマンドラインツール**: 必須
- **Disk 空き容量**: 2GB 以上推奨
- **ネットワーク**: インストール中に必要

### ✅ 現在の状態

```
✅ iOS シミュレータ: 利用可能
❌ Flutter: インストール必要
❌ 依存関係: インストール必要
```

---

## 方法A：Homebrew を使用（推奨・最速）

**所要時間**: 5-8分（最初のビルドは1-2分追加）

### ステップ1: Homebrew をインストール（初回のみ）

Homebrew がまだない場合：

```bash
# ターミナルを開く（⌘+Space → "ターミナル" で検索）

# Homebrew をインストール
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# パスワードを入力（複数回要求される場合がある）
# インストール完了を待つ
```

**確認:**
```bash
brew --version
# 出力例: Homebrew 4.x.x
```

---

### ステップ2: Homebrew パスを設定

```bash
# macOS のシェル設定ファイルを編集
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile

# 設定を反映
source ~/.zprofile

# 確認
echo $PATH | grep homebrew
```

---

### ステップ3: Flutter をインストール

```bash
# Flutter を Homebrew からインストール
brew install flutter

# インストール確認
flutter --version
# 出力例: Flutter 3.38.9 • channel stable
```

**ビルド時間**: 初回は1-2分かかります（以後は数秒）

---

### ステップ4: Xcode コマンドラインツールをインストール

```bash
# Xcode コマンドラインツールをインストール
xcode-select --install

# インストール確認
xcode-select -p
# 出力例: /Applications/Xcode.app/Contents/Developer
```

---

### ステップ5: Flutter 診断を実行

```bash
# 環境を診断
flutter doctor

# 出力例（最小要件）:
# [✓] Flutter (Channel stable, 3.38.9, on macOS 14.x.x)
# [✓] Xcode - develop for iOS
# [✓] Xcode build system
# [✓] iOS toolchain
# [✓] Devices
# ※ Android toolchain は不要
```

---

## 方法B：手動インストール（sudo不可の場合）

**所要時間**: 10-15分  
**用途**: Homebrew へのアクセス不可、またはカスタマイズしたい場合

### ステップ1: Flutter SDK を Git からクローン

```bash
# Development フォルダを作成
mkdir -p ~/development

# Flutter リポジトリをクローン（安定版のみ）
cd ~/development
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# 確認
ls -la flutter/bin/flutter
# 出力: -rwxr-xr-x ... flutter/bin/flutter
```

**クローン時間**: 30秒～2分（ネットワーク速度による）

---

### ステップ2: Flutter パスを設定

```bash
# シェル設定ファイルを編集
nano ~/.zprofile

# 以下を末尾に追加：
export PATH="$PATH:$HOME/development/flutter/bin"

# 保存して終了 (Ctrl+O → Enter → Ctrl+X)

# 設定を反映
source ~/.zprofile

# 確認
which flutter
# 出力: /Users/tomoki/development/flutter/bin/flutter
```

---

### ステップ3: Flutter を初期化

```bash
# Flutter 初期化（初回のみ時間がかかる）
flutter config --no-analytics

# Dart SDK をダウンロード（初回は1-2分）
flutter --version
```

---

### ステップ4: Xcode コマンドラインツールをインストール

```bash
# Xcode ツールをインストール
xcode-select --install

# 確認
xcode-select -p
# 出力: /Applications/Xcode.app/Contents/Developer
```

---

### ステップ5: Flutter 診断

```bash
flutter doctor
```

---

## セットアップ確認

### 診断を実行

```bash
flutter doctor -v
```

### 期待される出力

```
✓ Flutter
✓ Dart
✓ Xcode
✓ iOS toolchain
✓ Devices (iOS Simulator など)
```

### よくある警告（無視しても大丈夫）

- ❌ Android toolchain：iOS 開発には不要
- ⚠️ CocoaPods：ネイティブプラグイン使用時のみ必要
- ⚠️ Chrome：Dart DevTools に必須

---

## プロジェクト初期化

### ステップ1: プロジェクトフォルダに移動

```bash
cd /Users/tomoki/Desktop/flutter_app
```

### ステップ2: 依存関係をインストール

```bash
# pubspec.yaml から依存関係をインストール
flutter pub get

# 期待される出力:
# Running "flutter pub get" in flutter_app...
# Changed 82 dependencies!
```

### ステップ3: キャッシュを清理（初回推奨）

```bash
flutter clean
```

---

## アプリ実行

### パターン1：iOS シミュレータで実行（推奨）

```bash
# Step 1: iOS シミュレータを起動
open -a Simulator

# Step 2: シミュレータが起動するまで待つ（5-10秒）

# Step 3: アプリを実行
flutter run

# 初回起動は1-2分かかります...
# ビルドが完了するとシミュレータにアプリが表示されます
```

---

### パターン2：デバイスで実行

```bash
# 実機が接続されている場合
flutter run

# デバイス選択を促されたら選択
```

---

### パターン3：バックグラウンドで実行

```bash
# ターミナルウィンドウを開いたまま実行
flutter run

# 別のターミナルウィンドウで以下が使用可能:
flutter logs          # ログ表示
flutter reload        # ホットリロード
flutter restart       # 再起動
# Ctrl+C で終了
```

---

## ゲームの使い方

### 基本操作

1. **黒い駒をタップ**
   - 選択可能な駒が黄色でハイライト
   - 移動可能な位置が緑色のドットで表示

2. **緑色のドットをタップ**
   - 駒がその位置に移動
   - ターンが自動で交代

3. **白の手番**
   - CPU が自動で移動（数秒後）

### 実装済みルール

✅ 8種類の駒の完全な移動ルール  
✅ 成駒への変換＆必須成り  
✅ 王手検出＆王手放置防止  
✅ 詰み判定（ゲーム終了）  
✅ 駒台管理（捕獲駒のドロップ）  
✅ ドロップ禁止事項（二歩・打ち歩詰め等）  
✅ 千日手判定（4回繰り返し）

### 駒の種類

| 駒 | 動き | 成駒 |
|-------|------|------|
| **歩** | 前1マス | 成歩（金の動き） |
| **香** | 前に何マスでも | 成香（金の動き） |
| **桂** | L字形 | 成桂（金の動き） |
| **銀** | 斜め前4方向+後ろ中央 | 成銀（金の動き） |
| **金** | 前3方向+横2方向+後ろ中央 | 成らない |
| **角** | 斜め4方向 | 龍馬（角+1マス前後） |
| **飛** | 上下左右 | 龍王（飛+1マス左右） |
| **玉** | 8方向各1マス | 成らない |

---

## トラブルシューティング

### 問題 1: Flutter コマンドが見つからない

```bash
# 原因: PATH が設定されていない

# 解決策:
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zprofile
source ~/.zprofile
```

### 問題 2: iOS シミュレータが起動しない

```bash
# 解決策1: シミュレータを再起動
killall "com.apple.CoreSimulator.CoreSimulatorService"
open -a Simulator

# 解決策2: Xcode を再インストール
xcode-select --install
```

### 問題 3: アプリのビルドに失敗する

```bash
# キャッシュをクリア
flutter clean
rm -rf pubspec.lock

# 再度実行
flutter pub get
flutter run
```

### 問題 4: 古いバージョンが実行される

```bash
# Flutter をアップデート
flutter upgrade

# バージョン確認
flutter --version
```

### 問題 5: ホットリロードが動作しない

```bash
# ホットリロード: r
# 完全リスタート: R
# 終了: q

# または再度実行
flutter run
```

---

## 📊 セットアップ完了の確認

すべてが完了していることを確認：

```bash
✓ flutter --version        # Flutter 3.38.9 以上
✓ dart --version           # Dart 3.10.8 以上  
✓ flutter doctor           # [✓] すべて合格
✓ open -a Simulator        # シミュレータが起動
✓ flutter run              # アプリが実行される
✓ 将棋ゲームが表示される   # 9×9 ボード + 18 駒
```

---

## 🎯 次のステップ

1. **ゲームをプレイ**: 黒駒をタップして緑のドットで移動
2. **ログを確認**: `flutter logs` でエラーをチェック
3. **コード編集**: `lib/` フォルダのファイルを修正
4. **ホットリロード**: 編集後 `r` キーで反映

---

## 📞 サポート

問題が発生した場合：

1. **Flutter Doctor を実行**: `flutter doctor -v`
2. **ログを確認**: `flutter logs | grep -i error`
3. **キャッシュをクリア**: `flutter clean`
4. **再インストール**: `flutter pub get`

---

**最終更新**: 2026年2月4日  
**ステータス**: ✅ セットアップ完了・テスト準備完了
