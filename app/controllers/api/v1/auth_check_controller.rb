class Api::V1::AuthCheckController < ApplicationController
  before_action :authenticate_user!

  def index
    render json: { 
      message: "Successfully passed the Rails security gate",
      user_info: @current_user
    }, status: :ok
  end
end
