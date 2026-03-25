require 'rails_helper'

# 1. 看板をコントローラー名（単数）に合わせる
RSpec.describe "Api::V1::HealthCheck", type: :request do
  describe "GET /api/v1/health_check" do
    it "returns a 200 OK status and the correct JSON response" do
      # 2. 403エラーを回避するために、明示的に localhost を指定してアクセスする
      get "/api/v1/health_check", headers: { "Host" => "localhost" }

      # ステータスコードが 200 であることを確認
      expect(response).to have_http_status(:success)

      # 返ってきたJSONの中身を確認
      json_response = JSON.parse(response.body)
      expect(json_response["message"]).to eq("Hello, world!")
    end
  end
end
