# 実装仕様検証レポート（2026年2月5日）

## 📊 全体概要

| カテゴリ | 実装状況 | 進捗 |
|--------|--------|------|
| **フロントエンド画面** | 部分実装 | 70% |
| **認証・セキュリティ** | ダミー実装 | 10% |
| **バックエンド API** | 未実装 | 0% |
| **リアルタイム通信** | 未実装 | 0% |
| **通話機能** | スタブのみ | 5% |
| **決済処理** | ダミー実装 | 10% |

---

## 🎨 フロントエンド仕様 ✅ 部分実装

### 実装済み画面
- ✅ **ホーム画面** (`home_screen.dart`) — ナビゲーション・メニュー構造あり
- ✅ **指導者一覧** (`instructor_list_screen.dart`) — 検索・絞り込み（料金、評価）搭載
- ✅ **指導者プロフィール** (`instructor_profile_screen.dart`) — 自己紹介・レビュー・スケジュール表示
- ✅ **予約画面** (`reservation_screen.dart`) — カレンダー・時間選択・決済確認フロー
- ✅ **対局画面** (`shogi_game_screen.dart`) — 将棋盤 UI・棋譜表示基盤あり
- ✅ **マイページ** (`my_page_screen.dart`) — プロフィール編集・ログアウト
- ✅ **認証画面** (`auth_screen.dart`) — ログイン/新規登録 UI

### 未実装または限定的な画面
- ⚠️ **通話画面** (`call_service.dart`) — TODO コメント、スタブのみ
  - Chime SDK 統合なし
  - ビデオ通話機能なし
  - ミュート・スピーカー切替なし

### 実装済みロジック
- ✅ 将棋ルール検証（合法手判定、棋力判定、王手判定）
- ✅ 盤面管理（駒の配置、捕獲駒追跡）
- ✅ 棋譜管理（Move クラス、履歴機能）

### 未実装のロジック
- ❌ **AppSync WebSocket** — GraphQL Subscription で盤面同期なし
- ❌ **リアルタイム対局** — ローカルのみ、マルチプレイヤー非対応
- ❌ **チャット機能** — 対局画面に統合されていない
- ❌ **検討モード切替** — UI は存在するが機能なし

---

## 🔐 認証・セキュリティ ❌ 未実装

### 現状
- **AuthService**: ダミー実装（ローカルテスト用）
- トークン管理: `_authToken` をメモリに保持（永続化なし）
- ログイン検証: hardcoded メールアドレス・パスワード処理

### 仕様との差分
- ❌ **Cognito Hosted UI**: 未統合
- ❌ **JWT 検証**: API Gateway で検証していない
- ❌ **トークン永続化**: SecureStorage やキーチェーン利用なし
- ❌ **リフレッシュトークン**: 自動更新ロジックなし
- ❌ **Cognito 認証フロー**: OAuth2 / OIDC 未実装
- ⚠️ **ロール分離**: User / Instructor 区別はあるが権限制御なし

---

## 🌐 バックエンド API ❌ 未実装

### 期待される API 一覧

#### 認証関連（Cognito）
- ❌ `/auth/signup`
- ❌ `/auth/login`
- ❌ `/auth/refresh`

#### 指導者関連
- ❌ `GET /instructors`
- ❌ `GET /instructors/{id}`
- ❌ `GET /instructors/{id}/schedule`

#### 予約関連
- ❌ `POST /reservations`
- ❌ `POST /reservations/{id}/confirm`
- ❌ `DELETE /reservations/{id}`

#### 決済関連
- ❌ `POST /payments/create-session` (Stripe)
- ❌ `POST /payments/webhook`
- ❌ Webhook 署名検証
- ❌ 二重決済防止ロジック

#### 対局関連
- ❌ `POST /matches`
- ❌ `GET /matches/{id}`
- ❌ `POST /matches/{id}/finish` (棋譜保存)

#### 通話関連
- ❌ `POST /calls/create-meeting` (Chime)
- ❌ `POST /calls/join`

### 現在の実装
- **Repository クラス**: 存在するが実装なし（TODOコメント）
  - `InstructorRepository` — API 呼び出しなし
  - `ReservationRepository` — API 呼び出しなし
  - `MatchRepository` — API 呼び出しなし
  - `UserRepository` — API 呼び出しなし

- **Service クラス**: ダミー実装
  - `PaymentService` — ローカルでセッションID生成
  - `CallService` — ダミーミーティングIDのみ
  - `InstructorService` — 検索・フィルタロジック有り（サーバー連携なし）

---

## 🔄 リアルタイム通信（AppSync / WebSocket） ❌ 未実装

### 期待される実装
- ❌ GraphQL Schema 定義（Move, Match, Subscription）
- ❌ AppSync WebSocket 接続
- ❌ `onMove` Subscription — 盤面更新リアルタイム配信
- ❌ 差分送信による帯域最適化
- ❌ Cognito 認証による AppSync アクセス制御

### 現在の実装
- ❌ GraphQL クライアント設定あり（`graphql_flutter: ^5.1.0`）
- ❌ Subscription 実装なし
- ⚠️ 対局はローカルのみ（マルチプレイヤー非対応）

---

## 📞 通話機能（Chime / Agora） ❌ 未実装

### 期待される実装
- ❌ Chime SDK 統合（`amazon_chime_flutter` パッケージ等）
- ❌ ミーティング作成 API `/calls/create-meeting`
- ❌ 参加者トークン発行
- ❌ 音声通話デフォルト
- ❌ ビデオ通話オプション
- ❌ ミュート / スピーカー切替
- ❌ 通話品質ログ

### 現在の実装
- ⚠️ `CallService` クラス存在
  - `createMeeting()` — TODO コメント
  - `joinMeeting()` — TODO コメント
  - ダミー実装のみ

- ⚠️ `CallSession` モデル存在
  - meetingId, attendeeId, joinToken フィールド

---

## 💳 決済処理（Stripe） ⚠️ 限定的

### 期待される実装
- ❌ Stripe Checkout / PaymentSheet 統合（`flutter_stripe` パッケージ）
- ❌ `/payments/create-session` API 呼び出し
- ❌ Webhook 受信（`POST /payments/webhook`）
- ❌ Webhook 署名検証（Stripe Secret Key）
- ❌ 二重決済防止（DynamoDB トランザクション）
- ❌ 決済成功後の予約確定フロー

### 現在の実装
- ⚠️ `PaymentService` クラス存在
  - `createCheckoutSession()` — ダミーセッションID生成のみ
  - 実際の Stripe API 呼び出しなし
  - Webhook 処理なし
- ⚠️ 予約フロー
  - `ReservationSummaryCard` で金額・確認表示あり
  - 決済連携なし

---

## 📊 DynamoDB テーブル設計 ❌ 未実装

### 期待される テーブル
- ❌ **Users** テーブル
- ❌ **Instructors** テーブル
- ❌ **Reservations** テーブル
- ❌ **Matches** テーブル
- ❌ **Moves** テーブル（対局の手番記録）
- ❌ **Payments** テーブル

### 現在の実装
- ❌ バックエンド DB なし
- ✅ Dart モデルクラス存在（User, Instructor, Reservation など）

---

## 📦 依存関係の状態

### 現在の `pubspec.yaml`
```yaml
dependencies:
  flutter: sdk: flutter
  cupertino_icons: ^1.0.2
  graphql_flutter: ^5.1.0         ✓ AppSync/GraphQL 用
  provider: ^6.0.0                ✓ 状態管理
  http: ^1.1.0                    ✓ HTTP クライアント
  intl: ^0.18.0                   ✓ 国際化
```

### 不足している重要なパッケージ
- ❌ `amazon_chime_flutter` — Chime SDK
- ❌ `flutter_stripe` — Stripe 決済
- ❌ `flutter_secure_storage` — トークン永続化
- ❌ `aws_cognito_flutter` or `amplify_flutter` — Cognito 認証
- ❌ `aws_signature_v4` — Webhook 署名検証

---

## 🚀 優先度別実装ロードマップ

### 🔴 **Phase 1: Critical** (ビルドブロッカー)
1. **バックエンド API スケルトン構築** (Node.js Lambda + API Gateway)
   - `/auth/login`, `/auth/signup` endpoints
   - `/instructors`, `/reservations` endpoints（ダミーデータ）
   - 所要時間: 2-3 日

2. **Cognito 統合**
   - Cognito User Pool 設定
   - Hosted UI フロー
   - JWT トークン検証（API Gateway オーソライザー）
   - 所要時間: 1-2 日

3. **GraphQL / AppSync 基本設定**
   - GraphQL Schema 定義（Move, Match, User）
   - DynamoDB Resolvers
   - Subscription 実装（`onMove`）
   - 所要時間: 2-3 日

### 🟡 **Phase 2: High** (機能実装)
1. **Stripe 決済フロー**
   - `flutter_stripe` 統合
   - Webhook ハンドリング（Lambda）
   - Webhook 署名検証
   - 所要時間: 2-3 日

2. **Chime 音声通話**
   - `amazon_chime_flutter` SDK
   - `/calls/create-meeting` API
   - 参加者管理
   - 所要時間: 2-3 日

3. **リアルタイム対局**
   - AppSync Subscription（盤面同期）
   - 手番更新フロー
   - 対局終了・棋譜保存（S3）
   - 所要時間: 3-4 日

### 🟢 **Phase 3: Medium** (ポーランド)
1. **ビデオ通話オプション**
2. **チャット機能**（WebSocket）
3. **棋譜検討モード**
4. **支払い履歴・レビュー管理**

---

## 📋 チェックリスト（仕様完全実装まで）

### ✅ 完了
- [ ] ✅ Flutter UI/UX（画面構造）
- [ ] ✅ 将棋ルール検証エンジン

### ⏳ 進行中
- [ ] フロントエンド状態管理（Provider 統合進行中）

### ❌ 未着手
- [ ] REST API バックエンド（Lambda + API Gateway）
- [ ] DynamoDB テーブル設計・構築
- [ ] Cognito セットアップ
- [ ] AppSync GraphQL スキーマ
- [ ] Stripe Webhook ハンドリング
- [ ] Chime SDK 統合
- [ ] CloudWatch ロギング
- [ ] テスト（ユニット・統合テスト）

---

## 📝 結論

**現在の状態**: MVP（Minimum Viable Product）の **フロントエンド UI** が 70% 実装されている段階。バックエンド・認証・リアルタイム通信は **0% 実装**。

**推奨アクション**:
1. **バックエンド API スケルトン** を最優先で実装（1 週間）
2. **Cognito + JWT 認証** を統合（3-5 日）
3. **GraphQL / AppSync** でリアルタイム対局対応（1 週間）
4. **Stripe・Chime** を段階的に統合

**目安タイムライン**: 完全実装まで **4-6 週間**（フルタイム開発）

---

**生成日時**: 2026-02-05
**プロジェクト**: 87（はちなな）将棋 (将棋オンライン指導マッチングプラットフォーム)
