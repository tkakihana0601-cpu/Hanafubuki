# 📱 Flutter インストール - クイックガイド

## 現在のステータス

✅ iOS シミュレータ: 利用可能
❌ Flutter: インストール必要

---

## 🚀 インストール手順（5分で完了）

### ステップ1: Homebrewをインストール（まだの場合）

ターミナルを開いて以下を実行：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

パスワードを入力し、インストール完了まで待ちます。

### ステップ2: Flutterをインストール

```bash
# 確認
brew --version

# Flutterをインストール
brew install flutter

# 完了確認
flutter --version
```

### ステップ3: パスを確認

```bash
# 以下でflutterが表示されればOK
which flutter
```

---

## 🎮 アプリを実行

すべてのインストールが完了したら：

```bash
# プロジェクトフォルダに移動
cd /Users/tomoki/Desktop/flutter_app

# 依存関係をインストール
flutter pub get

# iOS シミュレータを起動
open -a Simulator

# アプリを実行
flutter run
```

---

## ⚠️ Homebrewをインストールできない場合

sudo パスワードなしでインストールしたい場合：

### 代替方法: SDK直接ダウンロード

```bash
# Flutter SDKをダウンロード
mkdir -p ~/development
cd ~/development

# Apple Silicon Macの場合:
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.24.0.zip

# Intel Macの場合:
# curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.24.0.zip

# 解凍
unzip flutter_macos_arm64_3.24.0.zip

# Pathを追加
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zprofile
source ~/.zprofile

# 確認
flutter --version
```

---

## 🔧 トラブルシューティング

### "Password required" が出る場合

Homebrewのインストール時に**管理者パスワード**が必要です。

```bash
# パスワードを入力してください
# ターミナルには入力内容が表示されません（これは正常）
```

### "flutter: command not found" が出る場合

```bash
# Pathを確認
cat ~/.zprofile | grep flutter

# なければ追加
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zprofile

# 反映
source ~/.zprofile

# 確認
flutter --version
```

### アプリが起動しない場合

```bash
# キャッシュをクリア
flutter clean

# 再度実行
flutter pub get
flutter run
```

---

## ✨ 次のステップ

1. **ターミナルで Homebrew をインストール** 
2. **Flutterをインストール**
3. **`flutter pub get` を実行**
4. **`flutter run` でアプリを起動**
5. **将棋ゲームをプレイ！🎮**

---

## 📞 詳細な情報

- 完全ガイド: [MANUAL_FLUTTER_INSTALL.md](MANUAL_FLUTTER_INSTALL.md)
- セットアップガイド: [SETUP_GUIDE.md](SETUP_GUIDE.md)
- クイックスタート: [QUICKSTART.md](QUICKSTART.md)

---

**楽しい開発を！🚀**

