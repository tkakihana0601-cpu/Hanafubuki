# 🚀 クイックスタート

## 📱 iOS シミュレータで実行（推奨・最速）

### ステップ1: 環境準備（1回だけ）

```bash
# Homebrewをインストール（なければ）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Flutterをインストール
brew install flutter

# Pathを設定
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile

# 診断を実行
flutter doctor
```

### ステップ2: プロジェクトセットアップ

```bash
# プロジェクトフォルダに移動
cd /Users/tomoki/Desktop/flutter_app

# 依存関係をインストール
flutter pub get
```

### ステップ3: アプリ実行

```bash
# iOS シミュレータを起動
open -a Simulator

# アプリを実行
flutter run

# 初回起動は数分待つ...
```

---

## 🎮 アプリの使い方

### 基本操作
1. **黒い駒をタップ** → 緑色のドットが合法手を表示
2. **緑色のドットをタップ** → 駒を移動
3. **ターンが自動で交代** → 後手がプレイ
4. **ゲーム終了** → 詰み or 千日手で自動判定

### ルール
- 敵陣で成駒に変更可能（プロンプト表示）
- 王手を放置してはいけない（自動チェック）
- 同じ局面が4回で千日手（引き分け）

---

## 📊 プロジェクト構成

```
flutter_app/
├── lib/
│   ├── main.dart              ← Boardクラス（盤面）
│   ├── models/                ← ドメインモデル
│   ├── services/              ← ゲームロジック (6つの検証エンジン)
│   └── screens/               ← UI (盤面表示)
├── SETUP_GUIDE.md             ← 詳細ガイド
├── COMPLETION_SUMMARY.md      ← 実装完成
└── demo.dart                  ← テストスクリプト
```

---

## ⚡ よくある質問

### Q: Flutterのインストールに時間がかかりますが？
**A:** 初回インストール時は5-10分かかります。コーヒーを飲みながら待ってください。

### Q: `flutter doctor` でエラーが出ています
**A:** 各エラーの下に対処法が表示されます。指示に従ってセットアップしてください。

### Q: アプリが起動しません
**A:** 以下を順番に試してください：
```bash
# 1. iOS シミュレータをリセット
xcrun simctl erase all

# 2. Flutter キャッシュをクリア
flutter clean

# 3. 再度実行
flutter pub get
flutter run
```

### Q: 駒がタップできません
**A:** アプリが完全に起動するまで30秒待ってください。初回起動は遅いです。

---

## 📚 詳細情報

- **SETUP_GUIDE.md** - 詳細なセットアップ手順
- **FINAL_IMPLEMENTATION_REPORT.md** - 実装の完全レポート
- **COMPLETION_SUMMARY.md** - 完成サマリー

---

## ✨ 実装済みルール

✅ 8種類の駒の完全な移動ルール
✅ 成駒への変換＆必須成り
✅ 王手検出＆王手放置防止
✅ 詰み判定（ゲーム終了）
✅ 駒台管理（捕獲駒のドロップ）
✅ ドロップ禁止事項（二歩・打ち歩詰め等）
✅ 千日手判定（4回繰り返し）

---

**楽しい対局を！🎮♟️**

