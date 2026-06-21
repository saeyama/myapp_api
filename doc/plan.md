# Cognito Post-Confirmation トリガー実装計画

## 目的

ユーザーがメール認証を完了したタイミングで、自動的にRDSへユーザー情報を登録する。

現在はReact（page.tsx）のコンポーネント描画時に `syncUser` を呼んでいるが、
ページが正常に読み込まれない場合に同期が漏れるリスクがある。
Lambda を使うことでフロントの状態に依存せず確実に同期できる。

---

## 実装後のフロー

```
ユーザーがメール認証完了
  ↓ （自動）
Cognito が Lambda を呼び出す（Post-Confirmation トリガー）
  ↓
Lambda が Rails API を叩く（POST /api/v1/sync_user）
  ↓
RDS にユーザー登録（新規 or 更新）
```

---

## 変更するファイル

### 1. `terraform/main.tf`
- Lambda の環境変数（`RAILS_API_URL`）を追加
- Cognito User Pool の Post-Confirmation トリガーに Lambda を紐付け
- ダミーコードを実際の Lambda コードに差し替え

### 2. `terraform/lambda/lambda_function.rb`（新規作成）
- Cognito から渡されるユーザー情報（sub, email, nickname）を取得
- Rails API（`POST /api/v1/sync_user`）を呼び出す
- イベントをそのまま return する（Cognito の仕様）

### 3. `myapp/app/page.tsx`
- `syncUser` の呼び出しを削除（Lambda に移譲するため）

---

## 既存の実装（変更不要）

- `app/controllers/api/v1/users_controller.rb` の `sync` アクション → そのまま使う
- `config/routes.rb` の `post 'sync_user'` → そのまま使う

---

## 実装手順

1. Lambda のコードを書く（`terraform/lambda/lambda_function.rb`）
2. `terraform/main.tf` を更新する
3. `terraform apply` で AWS に反映
4. Cognito コンソールでトリガーが設定されているか確認
5. `page.tsx` から `syncUser` の呼び出しを削除
6. 動作確認（新規サインアップ → RDS にユーザーが登録されるか）

---

## 注意事項

- Lambda は Cognito の Post-Confirmation イベント後にイベントをそのまま `return` する必要がある（しないと認証フローが止まる）
- Rails API の URL は Lambda の環境変数（`RAILS_API_URL`）で管理する
- `terraform apply` 前に必ず `terraform plan` で差分を確認する
