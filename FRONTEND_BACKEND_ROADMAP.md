# 📋 フロントエンド・バックエンド実装ロードマップ

**プロジェクト**: Flutter 87（はちなな）将棋アプリ  
**作成日**: 2026年2月4日  
**進捗**: 準備フェーズ

---

## 📊 現在の実装状況

### ✅ 完了している機能

#### フロントエンド
- **ゲームロジック**: ✅ 100% 完成（30 Dart ファイル、2500+ 行）
  - 8種の駒の移動ルール
  - 王手判定・詰み判定
  - 駒台管理・千日手判定

- **ドメインモデル**: ✅ 完成（8個）
  - User, Instructor, Reservation, ScheduleSlot, CallSession, Piece, Board, Move

- **サービス層**: ⚠️ 部分完成（6個）
  - AuthService（ダミー実装）
  - InstructorService（GraphQL 呼び出し想定）
  - ReservationService（メモリ内管理）
  - PaymentService（Stripe 連携想定）
  - MatchService（GraphQL Subscription）
  - CallService（Chime API 想定）

- **リポジトリ層**: ✅ 完成（4個）
  - UserRepository, InstructorRepository, ReservationRepository, MatchRepository

#### バックエンド
- ❌ **未実装**（AWS インフラなし）

#### UI 画面
- **実装済み**: 2個
  - ✅ shogi_game_screen.dart（将棋盤UI）
  - ✅ board_widget.dart（盤面表示）
  - ✅ match_screen.dart（対局画面）

- **未実装**: 5個
  - ❌ ホーム画面
  - ❌ 指導者一覧
  - ❌ 指導者プロフィール
  - ❌ 予約画面
  - ❌ マイページ

---

## 🎯 実装すべき機能（優先度順）

### フェーズ 1: フロントエンド基本画面（1-2週間）

#### 1-1. ホーム画面（HOME_SCREEN）
```
目的: メインエントリーポイント
内容:
  ├─ 指導対局ボタン
  ├─ 通常対局（CPU/オンライン）
  ├─ 棋譜管理ボタン
  └─ マイページボタン

画面構造:
  ├─ AppBar（ログイン状態表示）
  ├─ 4つのカードボタン
  └─ BottomNavigationBar
```

**作成ファイル**: `lib/screens/home_screen.dart`

---

#### 1-2. 指導者一覧画面（INSTRUCTOR_LIST_SCREEN）
```
目的: 講師を検索・選択
内容:
  ├─ 指導者リスト表示
  ├─ フィルタリング（料金、段位）
  ├─ 検索機能
  └─ 各講師をタップで詳細へ

画面構造:
  ├─ AppBar（検索・フィルタボタン）
  ├─ FilterPanel（料金、段位スライダー）
  ├─ InstructorListView
  │  └─ InstructorCard（段位・料金・レビュー表示）
  └─ BottomNavigationBar
```

**作成ファイル**: `lib/screens/instructor_list_screen.dart`
**追加**: `lib/widgets/instructor_card.dart`, `lib/widgets/filter_panel.dart`

---

#### 1-3. 指導者プロフィール画面（INSTRUCTOR_PROFILE_SCREEN）
```
目的: 講師詳細情報表示
内容:
  ├─ 自己紹介
  ├─ レビュー表示
  ├─ 料金表示
  ├─ 空きスケジュール
  └─ 「予約する」ボタン

画面構造:
  ├─ AppBar（戻る）
  ├─ InstructorProfileHeader
  │  ├─ プロフィール画像
  │  ├─ 名前・段位
  │  └─ 料金
  ├─ TabView
  │  ├─ 概要タブ
  │  ├─ レビュータブ
  │  └─ スケジュールタブ
  └─ 予約ボタン
```

**作成ファイル**: `lib/screens/instructor_profile_screen.dart`
**追加**: `lib/widgets/review_card.dart`, `lib/widgets/schedule_view.dart`

---

#### 1-4. 予約画面（RESERVATION_SCREEN）
```
目的: 講師予約・決済
内容:
  ├─ カレンダー表示
  ├─ 時間選択
  ├─ 料金確認
  ├─ 決済ボタン
  └─ 予約確認

画面構造:
  ├─ AppBar（戻る）
  ├─ DatePicker（カレンダー）
  ├─ TimePicker（時間選択）
  ├─ SummaryCard
  │  ├─ 選択情報
  │  ├─ 料金計算
  │  └─ 支払い方法
  └─ 「決済する」ボタン
```

**作成ファイル**: `lib/screens/reservation_screen.dart`
**追加**: `lib/widgets/calendar_picker.dart`, `lib/widgets/summary_card.dart`

---

#### 1-5. マイページ画面（MYPAGE_SCREEN）
```
目的: ユーザー情報管理
内容:
  ├─ プロフィール表示・編集
  ├─ 支払い履歴
  ├─ 予約一覧
  └─ ログアウト

画面構造:
  ├─ AppBar
  ├─ TabView
  │  ├─ プロフィールタブ
  │  ├─ 予約一覧タブ
  │  ├─ 支払い履歴タブ
  │  └─ 設定タブ
  └─ ログアウトボタン
```

**作成ファイル**: `lib/screens/mypage_screen.dart`
**追加**: `lib/widgets/profile_card.dart`, `lib/widgets/payment_history.dart`

---

#### 1-6. 認証画面（AUTH_SCREEN）
```
目的: ログイン・新規登録
内容:
  ├─ メール入力
  ├─ パスワード入力
  ├─ ログインボタン
  ├─ 新規登録ボタン
  └─ パスワード忘却リンク

画面構造:
  ├─ ブランディング（ロゴ）
  ├─ メールフィールド
  ├─ パスワードフィールド
  ├─ ログインボタン
  └─ 新規登録ボタン
```

**作成ファイル**: `lib/screens/auth_screen.dart`
**追加**: `lib/widgets/auth_form.dart`

---

### フェーズ 2: 実ユーザーデータ連携（2-3週間）

#### 2-1. GraphQL 基本設定
```
作成ファイル: lib/config/graphql_config.dart
内容:
  ├─ GraphQL クライアント初期化
  ├─ WebSocket 接続
  ├─ 認証トークン付与
  └─ エラーハンドリング
```

---

#### 2-2. AuthService 実装
```
ファイル修正: lib/services/auth_service.dart
機能:
  ├─ Cognito Hosted UI 統合
  ├─ トークン保存（local_storage）
  ├─ ログイン状態管理
  └─ 自動ログイン
```

---

#### 2-3. InstructorService 実装
```
ファイル修正: lib/services/instructor_service.dart
機能:
  ├─ GraphQL Query で指導者一覧取得
  ├─ フィルタリング
  ├─ ソート
  └─ ページネーション
```

---

#### 2-4. ReservationService 実装
```
ファイル修正: lib/services/reservation_service.dart
機能:
  ├─ 予約作成（仮予約）
  ├─ 決済確認後に確定
  ├─ キャンセル
  └─ 予約一覧取得
```

---

#### 2-5. PaymentService - Stripe 連携
```
ファイル修正: lib/services/payment_service.dart
機能:
  ├─ Stripe Checkout セッション作成
  ├─ PaymentSheet 統合
  ├─ 決済完了処理
  └─ エラーハンドリング

追加パッケージ: flutter_stripe
```

---

#### 2-6. MatchService - リアルタイム対局
```
ファイル修正: lib/services/match_service.dart
機能:
  ├─ GraphQL Subscription で盤面同期
  ├─ 手の配信
  ├─ 自動保存
  └─ 検討モード
```

---

#### 2-7. CallService - Chime 通話
```
ファイル修正: lib/services/call_service.dart
機能:
  ├─ Chime SDK 初期化
  ├─ ミーティング作成
  ├─ 参加者参加処理
  ├─ 音声/ビデオ制御
  └─ 通話品質監視

追加パッケージ: amazon_chime_flutter
```

---

### フェーズ 3: バックエンド実装（2-4週間）

#### 3-1. AWS インフラ基本設定
```
作成: aws/terraform/main.tf または aws/cloudformation/template.yaml
内容:
  ├─ API Gateway セットアップ
  ├─ Lambda IAM ロール
  ├─ DynamoDB テーブル作成
  ├─ AppSync セットアップ
  └─ Cognito User Pool
```

---

#### 3-2. REST API - 指導者関連
```
Lambda 関数:
  ├─ GET /instructors → ListInstructors
  ├─ GET /instructors/{id} → GetInstructor
  ├─ GET /instructors/{id}/schedule → GetSchedule
  └─ POST /instructors/{id}/review → CreateReview

作成ファイル: aws/lambda/instructors/
```

---

#### 3-3. REST API - 予約関連
```
Lambda 関数:
  ├─ POST /reservations → CreateReservation
  ├─ POST /reservations/{id}/confirm → ConfirmReservation
  ├─ DELETE /reservations/{id} → CancelReservation
  └─ GET /reservations → ListReservations

作成ファイル: aws/lambda/reservations/
```

---

#### 3-4. REST API - 決済関連
```
Lambda 関数:
  ├─ POST /payments/create-session → CreateCheckoutSession
  ├─ POST /payments/webhook → StripeWebhook
  └─ GET /payments/history → PaymentHistory

作成ファイル: aws/lambda/payments/
```

---

#### 3-5. REST API - 対局関連
```
Lambda 関数:
  ├─ POST /matches → CreateMatch
  ├─ GET /matches/{id} → GetMatch
  ├─ POST /matches/{id}/finish → FinishMatch
  └─ GET /matches/{id}/kifu → GetGameKifu

作成ファイル: aws/lambda/matches/
```

---

#### 3-6. REST API - 通話関連
```
Lambda 関数:
  ├─ POST /calls/create-meeting → CreateChimeMeeting
  ├─ POST /calls/join → JoinChimeMeeting
  └─ POST /calls/end → EndChimeMeeting

作成ファイル: aws/lambda/calls/
```

---

#### 3-7. AppSync GraphQL Schema
```
作成ファイル: aws/appsync/schema.graphql
内容:
  ├─ type User
  ├─ type Instructor
  ├─ type Match
  ├─ type Move
  ├─ Subscription onMove
  ├─ Mutation sendMove
  └─ Query getMatch

解析器: Resolver Lambda 関数
```

---

#### 3-8. DynamoDB テーブル
```
テーブル設計:
  ├─ Users テーブル
  ├─ Instructors テーブル
  ├─ Reservations テーブル
  ├─ Matches テーブル
  ├─ Moves テーブル
  ├─ PaymentHistory テーブル
  └─ ScheduleSlots テーブル

作成ファイル: aws/dynamodb/schema.json
```

---

#### 3-9. セキュリティ実装
```
実装内容:
  ├─ Cognito JWT 検証（API Gateway Authorizer）
  ├─ IAM ロール・ポリシー
  ├─ Stripe Webhook 署名検証
  ├─ CORS 設定
  └─ SSL/TLS（CloudFront）

作成ファイル: aws/security/authorizer.js
```

---

## 📈 実装タスク一覧（優先度順）

### 🔴 優先度 1: ホーム画面（必須）

```
[ ] 1. ホーム画面基本UI
[ ] 2. BottomNavigationBar 実装
[ ] 3. ナビゲーション遷移
```

### 🔴 優先度 2: 認証画面（必須）

```
[ ] 4. ログイン画面UI
[ ] 5. 新規登録画面UI
[ ] 6. AuthService - Cognito 連携
```

### 🟡 優先度 3: 指導者関連画面（重要）

```
[ ] 7. 指導者一覧画面
[ ] 8. フィルタリング機能
[ ] 9. 指導者プロフィール画面
[ ] 10. InstructorService 実装（GraphQL 連携）
```

### 🟡 優先度 4: 予約・決済（重要）

```
[ ] 11. 予約画面UI
[ ] 12. PaymentService - Stripe 連携
[ ] 13. ReservationService 実装
```

### 🟢 優先度 5: マイページ（追加機能）

```
[ ] 14. マイページ画面
[ ] 15. プロフィール編集機能
[ ] 16. 支払い履歴表示
```

### 🟢 優先度 6: バックエンド実装（後続）

```
[ ] 17. AWS インフラ構築
[ ] 18. Lambda 関数実装
[ ] 19. DynamoDB テーブル設計
[ ] 20. AppSync GraphQL Schema
```

---

## 📦 必要な追加パッケージ

```yaml
dependencies:
  # 認証
  flutter_appauth: ^6.0.0              # OAuth2 / OpenID Connect
  aws_cognito_flutter: ^1.0.0          # AWS Cognito

  # UI
  table_calendar: ^3.0.0               # カレンダー
  flutter_time_picker_spinner: ^2.0.0  # 時間ピッカー
  shimmer: ^3.0.0                      # ローディング
  
  # 決済
  flutter_stripe: ^9.0.0               # Stripe
  
  # GraphQL
  graphql_flutter: ^5.1.0              # ✅ 既存
  
  # 通話
  amazon_chime_flutter: ^1.0.0         # AWS Chime
  
  # ローカルストレージ
  shared_preferences: ^2.0.0           # トークン保存
  flutter_secure_storage: ^9.0.0       # 暗号化保存
  
  # ネットワーク
  http: ^1.1.0                         # ✅ 既存
  dio: ^5.0.0                          # REST クライアント
  
  # 状態管理
  provider: ^6.0.0                     # ✅ 既存
  riverpod: ^2.0.0                     # 高度な状態管理（オプション）
  
  # 日時
  intl: ^0.18.0                        # ✅ 既存
  timezone: ^0.9.0
  
  # その他
  json_serializable: ^6.0.0            # JSON 生成
  json_annotation: ^4.0.0
```

---

## 🚀 実装開始の推奨手順

### ステップ 1: 基本画面構造（Day 1-2）

1. **ホーム画面** を作成
2. **BottomNavigationBar** で他の画面へ遷移
3. 各画面の基本 UI をダミーで実装

### ステップ 2: 認証フロー（Day 3-4）

1. **ログイン画面** UI
2. **AuthService** を Cognito に接続
3. ログイン状態の保持

### ステップ 3: データ表示（Day 5-7）

1. **指導者一覧** GraphQL から取得
2. **指導者プロフィール** 表示
3. フィルタリング機能

### ステップ 4: 予約・決済（Day 8-10）

1. **予約画面** UI
2. **Stripe** 決済連携
3. 予約確認

### ステップ 5: バックエンド（以降）

1. AWS インフラ構築
2. Lambda 関数実装
3. GraphQL Schema 設定

---

## 📝 次のアクション

**どの機能から実装を始めますか？**

推奨順序:
1. ✅ **ホーム画面** （全体構造の基盤）
2. ✅ **認証画面** （ユーザー管理の基盤）
3. ✅ **指導者一覧** （データ表示の最初のステップ）

**提案**: まずは **ホーム画面** から始めましょう。3-4時間で完成できます。

---

**作成日**: 2026年2月4日  
**ステータス**: 📋 ロードマップ確定待ち
