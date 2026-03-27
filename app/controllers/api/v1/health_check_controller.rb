class Api::V1::HealthCheckController < ApplicationController
  def index
    render json: { message: 'Hello, world!!!' } , status: :ok
  end
end
