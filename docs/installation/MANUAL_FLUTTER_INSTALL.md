# 🚀 Flutter インストール - 手動セットアップガイド

Homebrewへのsudoアクセスがない場合は、このガイドに従ってFlutter SDKを手動でインストールしてください。

---

## 📥 方法1: SDK直接ダウンロード（推奨）

### ステップ1: Flutter SDKをダウンロード

macOS Apple Siliconの場合：

```bash
# Developmentフォルダを作成
mkdir -p ~/development

# Flutterフォルダに移動
cd ~/development

# Flutter SDKをダウンロード（~500MB）
# ブラウザで https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.24.0.zip
# または以下のコマンド:
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.24.0.zip

# 解凍
unzip flutter_macos_arm64_3.24.0.zip

# 確認
ls -la flutter/bin/flutter
```

### ステップ2: Pathを設定

```bash
# ~/.zprofile を編集
nano ~/.zprofile

# 以下の行を追加:
export PATH="$PATH:$HOME/development/flutter/bin"

# ファイルを保存 (Ctrl+O, Enter, Ctrl+X)

# Pathを反映
source ~/.zprofile

# 確認
echo $PATH | grep flutter
```

### ステップ3: Flutterを初期化

```bash
# Flutter SDKを初期化
flutter config --no-analytics

# 診断を実行
flutter doctor
```

### ステップ4: Xcodeコマンドラインツールをインストール

```bash
# Xcodeツールをインストール
xcode-select --install

# インストール完認
xcode-select -p
# 出力: /Applications/Xcode.app/Contents/Developer
```

---

## 📥 方法2: macOS App Storeから Xcode をインストール

```bash
# 1. App Storeから Xcode をインストール（数GB必要）
open "macappstore://apps.apple.com/app/xcode/id497799835"

# 2. インストール完了後、コマンドラインツールを設定
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# 3. ライセンスに同意
sudo xcodebuild -license accept

# 4. Dart SDK をインストール
flutter precache
```

---

## 🔍 インストール確認

すべてが正常か確認：

```bash
# バージョンを確認
flutter --version
dart --version

# 詳細な診断を実行
flutter doctor -v

# 出力例:
# [✓] Flutter (Channel stable, 3.24.0, on macOS 14.x, locale ja-JP)
# [✓] Android toolchain - develop for Android devices
# [✓] Xcode - develop for iOS and macOS
# [✓] Xcode build system is healthy
```

---

## 🎮 アプリを実行

すべてのインストールが完了したら：

```bash
cd /Users/tomoki/Desktop/flutter_app

# 依存関係をインストール
flutter pub get

# iOS シミュレータを起動
open -a Simulator

# アプリを実行
flutter run
```

---

## ⚠️ よくある問題

### 問題: "flutter: command not found"

**解決:**
```bash
# Pathが正しく設定されているか確認
echo $PATH

# Flutterが存在するか確認
ls -la ~/development/flutter/bin/flutter

# ~/.zprofile を再度確認
cat ~/.zprofile | grep flutter

# 必要に応じて再度追加
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zprofile
source ~/.zprofile
```

### 問題: "Xcode is not installed"

**解決:**
```bash
# Xcode Command Line Tools をインストール
xcode-select --install

# インストール完了を待つ（15-20分）
```

### 問題: iOS シミュレータが起動しない

**解決:**
```bash
# シミュレータをリセット
xcrun simctl erase all

# 新しいシミュレータを作成
xcrun simctl create "iPhone 15" com.apple.CoreSimulator.SimDeviceType.iPhone-15
```

---

## 📋 チェックリスト

- [ ] Flutter SDK をダウンロード & 解凍
- [ ] Pathに `$HOME/development/flutter/bin` を追加
- [ ] `source ~/.zprofile` で設定を反映
- [ ] `flutter --version` で バージョン確認
- [ ] `flutter doctor` でエラーなし
- [ ] Xcode Command Line Tools インストール済み
- [ ] `flutter pub get` 成功
- [ ] `flutter run` でアプリ起動

---

## 🎯 次のステップ

1. 上記のいずれかの方法でFlutterをインストール
2. `flutter doctor` で エラーを確認
3. `flutter run` でアプリを起動
4. iOS シミュレータで将棋ゲームをプレイ！

---

**質問がある場合は、SETUP_GUIDE.md を参照してください。**

