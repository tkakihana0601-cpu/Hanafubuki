# 🎮 Flutter 将棋ゲーム

完全な将棋ゲーム実装です。すべてのルールが実装済みで本番運用可能です。

## 🚀 はじめ方

**→ まず [START_HERE.md](START_HERE.md) を開いてください！**

このファイルに以下の情報が記載されています：
- プロジェクト構成
- インストール手順
- ゲームの使い方
- ドキュメントリンク

---

## 📁 インストール関連ファイル

すべてのFlutter/インストール関連ファイルは `docs/installation/` にあります：

```
docs/installation/
├── INSTALL_NOW.md              ← 今すぐインストール！
├── QUICKSTART.md               ← 3ステップガイド
├── SETUP_GUIDE.md              ← 詳細セットアップ
├── MANUAL_FLUTTER_INSTALL.md   ← 手動インストール
├── setup_flutter_auto.sh       ← 自動スクリプト
└── check_flutter.sh            ← チェックスクリプト
```

---

## 📚 ドキュメント

| ドキュメント | 内容 |
|------------|------|
| **START_HERE.md** | 🚀 最初に読む |
| **INDEX.md** | 📑 全ドキュメント一覧 |
| **docs/installation/INSTALL_NOW.md** | 🚀 今すぐインストール |
| **COMPLETION_SUMMARY.md** | ✅ 実装完成 |
| **FINAL_IMPLEMENTATION_REPORT.md** | 📊 完全レポート |
| **SHOGI_LOGIC_REPORT.md** | 🎯 ゲーム仕様書 |

---

## ✨ 実装済みルール

✅ 8種類の駒の完全な移動ルール
✅ 成駒への変換＆必須成り
✅ 王手検出＆王手放置防止
✅ 詰み判定
✅ 駒台管理＆ドロップ
✅ ドロップ禁止事項（二歩・打ち歩詰め等）
✅ 千日手判定

---

## 🎮 ゲーム使用方法

- Flutter SDK
- Dart SDK

### セットアップ

```bash
flutter pub get
```

### 実行

```bash
flutter run
```

### ビルド

```bash
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web
```

## プロジェクト構成

- `lib/main.dart` - メインのアプリケーションファイル
- `pubspec.yaml` - プロジェクト設定

## さらに詳しく

- [Flutter ドキュメント](https://flutter.dev/docs)
- [Dartドキュメント](https://dart.dev)
