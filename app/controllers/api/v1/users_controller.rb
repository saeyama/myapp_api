class Api::V1::UsersController < ApplicationController
  def sync
    # Lambdaから送られてくる予定のデータを受け取る
    cognito_sub = params[:cognito_sub]
    email = params[:email]
    nickname = params[:nickname]

    # subが空っぽならエラーで返す（安全対策）
    if cognito_sub.blank?
      render json: { error: 'cognito_subは必須です' }, status: :bad_request
      return
    end

    # Usersテーブルから同じsubを持つ人を探し、いなければ新規作成する（find_or_create_by）
    user = User.find_or_create_by(cognito_sub: cognito_sub) do |u|
      u.email = email
      u.nickname = nickname
    end

    # 無事に保存（または取得）できたかどうかの結果を返す
    if user.persisted?
      render json: { message: 'ユーザーの同期が完了しました', user: user }, status: :ok
    else
      render json: { error: '保存に失敗しました', errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
