class Api::V1::UsersController < ApplicationController
  # 必要であればここで認証チェック（JWT検証など）を入れる
  # before_action :authenticate_request 

  def sync
    # フロントエンドから送られてきたデータを安全に取得
    sub = params[:cognito_sub]
    
    if sub.blank?
      render json: { error: 'cognito_subは必須です' }, status: :bad_request
      return
    end

    # 1. 既存のユーザーを探すか、新規インスタンスを作成
    # 2. find_or_initialize_byを使うと、見つかった場合にその後の項目更新が楽になります
    user = User.find_or_initialize_by(cognito_sub: sub)
    
    # 3. 送られてきた最新情報で属性を上書き（同期）
    user.email = params[:email]
    user.nickname = params[:nickname]

    # 4. 保存（更新があれば更新、新規なら作成）
    if user.save
      render json: { message: 'ユーザーの同期が完了しました', user: user }, status: :ok
    else
      render json: { error: '保存に失敗しました', errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
