# 🚀 Flutter 将棋ゲーム - セットアップガイド

## インストール環境

**システム**: macOS (Apple Silicon)
**プロジェクト**: Flutter 将棋ゲーム
**状態**: ✅ コード完成・テスト準備完了

---

## 📋 セットアップ手順

### ステップ1: Homebrewをインストール

```bash
# ターミナルを開いて以下を実行
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# パスワードを入力
# インストール完了後、以下でPathを設定
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**確認:**
```bash
brew --version  # Homebrew 4.x.x が表示されれば成功
```

---

### ステップ2: Flutterをインストール

```bash
# Flutterをインストール
brew install flutter

# インストール確認
flutter --version  # Flutter 3.x.x が表示されれば成功

# Flutterの診断を実行
flutter doctor
```

**出力例:**
```
[✓] Flutter (Channel stable, 3.24.0, on macOS 14.x.x, locale ja-JP)
[✓] Android toolchain - develop for Android devices
[✓] Xcode - develop for iOS and macOS
[✓] Xcode build system is healthy
```

---

### ステップ3: プロジェクトのセットアップ

```bash
# プロジェクトディレクトリに移動
cd /Users/tomoki/Desktop/flutter_app

# 依存関係をインストール
flutter pub get

# 出力例:
# Running "flutter pub get" in flutter_app...
# Resolving dependencies... (数秒かかります)
# Got dependencies!
```

---

### ステップ4: アプリを実行

#### 方法A: iOS シミュレータで実行（推奨）

```bash
cd /Users/tomoki/Desktop/flutter_app

# iOS シミュレータを起動
open -a Simulator

# アプリを実行
flutter run

# 出力例:
# Launching lib/main.dart on iPhone 15 Pro in debug mode...
# Running Gradle tasks to find and install build outputs...
# Xcode build done.
# Running...
```

#### 方法B: 実機で実行

```bash
# iPhoneを接続してから
cd /Users/tomoki/Desktop/flutter_app
flutter devices  # デバイスを確認

# デバイスを指定して実行
flutter run -d <device-id>
```

---

## 🧪 ゲームのテスト方法

### UI でのテスト

1. **アプリ起動後、ShogiGameScreenが表示されます**
   - 9×9 の将棋盤が表示
   - 両側に16個の駒が配置

2. **駒を選択**
   - 黒（先手）の駒をタップ
   - 緑色のドットで合法手が表示される

3. **駒を移動**
   - 緑色のドット（合法手）をタップ
   - 自動で王手放置チェック
   - ターンが交代

4. **ゲーム終了**
   - 詰み → ゲーム終了メッセージ
   - 千日手 → 引き分けメッセージ

### コマンドラインテスト

```bash
# プロジェクトディレクトリで
cd /Users/tomoki/Desktop/flutter_app

# ユニットテストを実行
flutter test

# 統合テストを実行
dart run_integration_test.dart
```

---

## 🔧 トラブルシューティング

### 問題: "flutter command not found"

**解決:**
```bash
# Pathを設定
echo 'export PATH="$PATH:$HOME/development/flutter/bin"' >> ~/.zprofile
source ~/.zprofile
```

### 問題: "Xcode is not installed"

**解決:**
```bash
# Xcode Command Line Tools をインストール
xcode-select --install
```

### 問題: iOS シミュレータが起動しない

**解決:**
```bash
# シミュレータをリセット
xcrun simctl erase all

# 新しいシミュレータを作成
xcrun simctl create "iPhone 15" com.apple.CoreSimulator.SimDeviceType.iPhone-15 com.apple.CoreSimulator.SimRuntime.iOS-17-2
```

---

## ✅ 確認チェックリスト

- [ ] Homebrewがインストール済み (`brew --version`)
- [ ] Flutterがインストール済み (`flutter --version`)
- [ ] `flutter doctor` にエラーがない
- [ ] `flutter pub get` が成功した
- [ ] iOS シミュレータが起動できる
- [ ] `flutter run` でアプリが起動する
- [ ] 盤面に18個の駒が表示されている
- [ ] 駒をタップすると合法手が表示される
- [ ] ゲーム状態メッセージが表示される

---

## 📊 プロジェクト構成

```
flutter_app/
├── lib/
│   ├── main.dart                    ← Boardクラス（9×9盤面）
│   ├── models/                      ← ドメインモデル
│   │   ├── piece.dart              (14駒タイプ)
│   │   ├── user.dart
│   │   └── ...
│   ├── services/                    ← ビジネスロジック
│   │   ├── shogi_game_state.dart   (ゲーム状態)
│   │   ├── check_detector.dart     (王手検出)
│   │   ├── legal_move_validator.dart (合法手)
│   │   ├── captured_piece_manager.dart (駒台)
│   │   ├── drop_move_validator.dart (ドロップ)
│   │   ├── draw_detector.dart      (千日手)
│   │   ├── shogi_game_validator.dart (統一検証)
│   │   └── ...
│   └── screens/                     ← UI層
│       ├── shogi_game_screen.dart  (メイン画面)
│       ├── board_widget.dart       (盤面表示)
│       └── ...
├── pubspec.yaml                     ← 依存関係定義
├── COMPLETION_SUMMARY.md            ← 実装完成ガイド
└── run_integration_test.dart        ← テストスクリプト
```

---

## 🎮 ゲームルール簡易ガイド

### 駒の動き
- **歩 (♟)**: 前に1マス
- **香 (🌾)**: 前に何マスでも
- **桂 (🐴)**: L字（前2マス + 左右1マス）
- **銀 (🛡️)**: 斜め前4方向 + 後ろ中央
- **金 (👑)**: 前3方向 + 横2方向 + 後ろ中央
- **角 (🎯)**: 斜め4方向
- **飛 (✈️)**: 上下左右（何マスでも）
- **玉 (👸)**: 8方向各1マス

### ルール
- 敵の駒を敵陣で移動すると「成駒」に変更可能
- 歩・香が敵陣最終段では必ず成る（必須成り）
- 王手状態を放置してはいけない（王手放置禁止）
- 同じ局面が4回繰り返されると千日手（引き分け）

---

## 📚 詳細ドキュメント

より詳しい情報は、以下を参照してください：

- **COMPLETION_SUMMARY.md** - 実装完成サマリー
- **FINAL_IMPLEMENTATION_REPORT.md** - 最終実装レポート
- **SHOGI_LOGIC_REPORT.md** - 仕様書

---

## 🎯 次のステップ

1. **Homebrewをインストール** → **Flutterをインストール**
2. **`flutter pub get`** で依存関係をインストール
3. **`flutter run`** でアプリを起動
4. **盤面をタップ**して将棋ゲームをプレイ！

---

**楽しい対局を！🎮♟️**

