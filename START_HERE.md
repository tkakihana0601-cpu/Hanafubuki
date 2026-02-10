# 🚀 Flutter 将棋ゲーム - セットアップガイド

## 📁 プロジェクト構成

```
flutter_app/
├── docs/installation/              ← ⭐ Flutter インストール関連
│   ├── INSTALL_NOW.md             (今すぐインストール)
│   ├── QUICKSTART.md              (3ステップガイド)
│   ├── SETUP_GUIDE.md             (詳細セットアップ)
│   ├── MANUAL_FLUTTER_INSTALL.md  (手動インストール)
│   ├── INSTALLATION_COMPLETE.md   (完了レポート)
│   ├── install_flutter.sh         (自動スクリプト)
│   ├── check_flutter.sh           (チェックスクリプト)
│   └── setup_flutter_auto.sh      (セットアップスクリプト)
│
├── lib/                           ← ゲームコード
│   ├── main.dart                  (Entry point)
│   ├── models/                    (ドメインモデル)
│   ├── services/                  (ゲームロジック)
│   └── screens/                   (UI)
│
├── backend/                       ← GraphQL & Lambda
├── test/                         ← テスト
│
├── INDEX.md                      ← ドキュメント一覧
├── COMPLETION_SUMMARY.md         ← 実装完成
├── FINAL_IMPLEMENTATION_REPORT.md ← 詳細レポート
└── pubspec.yaml                  ← 依存関係
```

---

## 🎯 はじめ方

### ⭐ **最初に `docs/installation/FLUTTER_INSTALLATION_GUIDE.md` を開く**

完全な統合ガイドです。すべてのセットアップ方法とトラブルシューティングが含まれています。

```bash
open docs/installation/FLUTTER_INSTALLATION_GUIDE.md
```

### クイックスタート（急いでいる場合）

```bash
# ステップ1: Homebrew でインストール
brew install flutter

# ステップ2: プロジェクト初期化
cd /Users/tomoki/Desktop/flutter_app
flutter pub get

# ステップ3: アプリ実行
open -a Simulator
flutter run
```

---

## 📚 ドキュメント

| ドキュメント | 内容 |
|------------|------|
| **docs/installation/INSTALL_NOW.md** | 🚀 今すぐインストール |
| **docs/installation/QUICKSTART.md** | ⚡ 3ステップガイド |
| **docs/installation/SETUP_GUIDE.md** | 📋 詳細セットアップ |
| **INDEX.md** | 📑 全ドキュメント一覧 |
| **COMPLETION_SUMMARY.md** | ✅ 実装完成 |
| **FINAL_IMPLEMENTATION_REPORT.md** | 📊 完全レポート |

---

## ✨ インストール関連ファイルの格納場所

すべてのFlutter/インストール関連ファイルは `docs/installation/` にまとめられています：

### 📄 ドキュメント (5つ)
- INSTALL_NOW.md
- QUICKSTART.md
- SETUP_GUIDE.md
- MANUAL_FLUTTER_INSTALL.md
- INSTALLATION_COMPLETE.md

### 🔧 スクリプト (3つ)
- install_flutter.sh
- check_flutter.sh
- setup_flutter_auto.sh

---

## 🎮 ゲームの使い方

1. **黒い駒をタップ** → 緑色のドットが合法手を表示
2. **緑色のドットをタップ** → 駒が移動
3. **ターンが自動で交代** → 後手がプレイ
4. **ゲーム終了** → 詰み or 千日手で自動判定

---

## ✅ 実装済みルール

✅ 駒の種類と基本移動ルール
✅ 駒の成り判定と必須成り
✅ 王手（チェック）検出
✅ 王手放置禁止
✅ 詰み（チェックメイト）判定
✅ 駒台管理
✅ ドロップ禁止事項
✅ 千日手判定

---

## 🚀 クイックリンク

```bash
# インストール関連
cd docs/installation

# すぐに始める
open INSTALL_NOW.md

# スクリプトを実行
bash setup_flutter_auto.sh
```

---

**楽しい開発を！🎮♟️**

