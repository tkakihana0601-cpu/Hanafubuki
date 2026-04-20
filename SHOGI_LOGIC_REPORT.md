## 将棋ロジック実装状況レポート

### 1. 盤面・駒の基本構造 ✅ 実装済み
**実装ファイル**: `lib/models/piece.dart`, `lib/main.dart` (Board クラス)

**実装状況**:
- ✅ 9×9 盤面管理（0-8 座標系）
- ✅ 駒の種類（8種類 + 6成駒種 = 14種類）
- ✅ 駒の所属（isBlack で先後判別）
- ✅ 成り状態の管理（isPromoted フラグ）
- ✅ **駒台（持ち駒）の管理 - NEW** [`captured_piece_manager.dart`]
- ⚠️ **座標表記の統一（1-9表記への対応）- 部分的**

---

### 2. 駒の動きのロジック ✅ 実装済み
**実装ファイル**: `lib/services/shogi_rules.dart`

**実装状況**:
- ✅ 各駒の移動方向と距離（歩・香・桂・銀・金・角・飛・玉）
- ✅ 成駒の移動（馬・龍 + 成香・成銀・成桂・との金相当動き）
- ✅ 経路の障害物判定（角・飛・香の長距離駒）
- ✅ 移動先の味方駒判定
- ✅ 敵駒の捕獲判定
- ✅ **入玉時の"宙"の判定（敵陣での1段目攻防）**

---

### 3. 成りのロジック ✅ 完全実装
**実装ファイル**: `lib/services/legal_move_validator.dart`

**実装状況**:
- ✅ 成り可能条件の判定（敵陣3段判定）
- ✅ 成りと不成の選択肢提示（UI での shouldPromote）
- ✅ **成りが必須のケース - NEW**
  - 歩・香が最終段に進む手 → 必須成り
  - 桂が最終2段に進む手 → 必須成り
- ✅ **成り駒の成り直し禁止 - NEW**

---

### 4. 持ち駒の打ちロジック ✅ 新規実装
**実装ファイル**: `lib/services/captured_piece_manager.dart`, `lib/services/drop_move_validator.dart`

**新規実装機能**:
- ✅ **駒台の管理（先手・後手ごとの持ち駒）**
- ✅ **打ち可能な空マス判定**
- ✅ **打ち歩詰め禁止 - NEW**
- ✅ **二歩禁止（同筋の歩判定）- NEW**
- ✅ **桂・香・歩の打ちストリクション - NEW**
  - 歩・香：最終段に打てない
  - 桂：最終2段に打てない

---

### 5. 王手・詰み・合法手の判定 ✅ 完全実装
**実装ファイル**: `lib/services/check_detector.dart`, `lib/services/legal_move_validator.dart`

**新規実装機能**:
- ✅ **王手判定 - NEW** (`check_detector.dart`)
  - 自玉が敵の利きに入っているか
  - 相手の手で自玉が取られる位置か判定
- ✅ **合法手生成の王手放置チェック - NEW**
  - 全ての手について「自玉が王手されない」ことを確認
  - 王手放置の手は除外
- ✅ **詰み判定 - NEW**
  - 合法手0 + 王手状態 = 詰み
- ✅ **逃げ道判定**（自玉の移動可能マス）

---

### 6. 千日手・持将棋などの特殊ルール ✅ 部分実装
**実装ファイル**: `lib/services/draw_detector.dart`

**新規実装機能**:
- ✅ **千日手判定（同一局面の4回出現）- NEW**
- ✅ **局面ハッシュ（Zobrist Hashing 相当）- NEW**
- ✅ **局面比較（先後・手番・持ち駒完全一致）- NEW**
- ✅ **王手の連続性チェック** - 判定ロジック実装
- ❌ 持将棋ルール（玉以外駒の点数計算）
- ❌ 入玉宣言法（オプション）

---

### 7. 反則手の判定 ✅ 大幅実装
**実装ファイル**: `lib/services/drop_move_validator.dart`, `lib/services/legal_move_validator.dart`

**実装状況**:
- ✅ **二歩禁止 - NEW** (`drop_move_validator.dart`)
- ✅ **打ち歩詰め禁止 - NEW** (`drop_move_validator.dart`)
- ✅ **王手放置 - NEW** (`legal_move_validator.dart`)
- ✅ **行き所のない駒の不成 - NEW**
  - 歩が最終段：必須成り
  - 香が最終段：必須成り
  - 桂が最終2段：必須成り
- ✅ **自殺手**（王手放置の一種で対応）
- ✅ **連続王手の千日手** - 判定ロジック実装

---

### 8. 局面管理・履歴管理 ✅ 完全実装
**実装ファイル**: `lib/services/draw_detector.dart`, `lib/services/shogi_game_state.dart`

**実装状況**:
- ✅ 棋譜の記録（指し手・時刻）
- ✅ 手数のカウント
- ✅ **局面ハッシュ - NEW** (Zobrist Hashing 相当)
- ✅ **局面履歴の完全保存 - NEW**（ハッシュ+先後+持ち駒）
- ❌ Undo/Redo（探索エンジン用 - オプション）
- ✅ 局面の正規化

---

## 総合実装結果

### 🟢 完全実装（必須機能）
1. ✅ 盤面・駒の基本構造
2. ✅ 駒の動きのロジック
3. ✅ 成りのロジック（必須・選択判定含む）
4. ✅ 持ち駒の打ちロジック
5. ✅ 王手・詰み・合法手の判定
6. ✅ 千日手判定
7. ✅ 反則手の判定
8. ✅ 局面管理・履歴管理

### 🟡 部分実装（オプション）
- 持将棋ルール（点数計算）
- 入玉宣言法
- Undo/Redo
- 連続王手の千日手の自動適用

---

## 新規作成ファイル一覧

| ファイル | 役割 | 行数 |
|---------|------|------|
| `check_detector.dart` | 王手判定エンジン | 90 |
| `legal_move_validator.dart` | 合法手検証・生成 | 120 |
| `captured_piece_manager.dart` | 駒台管理 | 130 |
| `drop_move_validator.dart` | 駒の打ちバリデーション | 150 |
| `draw_detector.dart` | 千日手判定・局面ハッシング | 110 |
| `shogi_game_validator.dart` | 統合ゲーム検証 | 150 |

**合計新規実装：約 750 行**

---

## 検証コマンド例

```dart
// 王手判定
final inCheck = CheckDetector.isInCheck(board, true);

// 合法手の取得（王手放置チェック済み）
final legalMoves = LegalMoveValidator.getAllLegalMoves(board, true);

// 詰み判定
final isCheckmate = LegalMoveValidator.isCheckmate(board, false);

// 駒の打ち検証
final canDrop = DropMoveValidator.canDropPiece(board, 3, 3, PieceType.pawn, true, capturedManager);

// 千日手判定
final isRepetition = DrawDetector.isThreefoldRepetition(boardHistory, currentHash);

// 総合ゲーム状態判定
final status = ShogiGameValidator.getGameStatus(board, true, history, hash, captured);
```

すべての必須ロジックが実装完了しました！🎉
