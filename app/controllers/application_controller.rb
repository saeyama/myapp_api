class ApplicationController < ActionController::API
  attr_reader :current_user

  def authenticate_user!
    header = request.headers['Authorization']
    token = header.split(' ').last if header.present?

    decoded_token = CognitoJwtVerifier.verify(token)

    if decoded_token
      @current_user = decoded_token
    else
      render json: { error: 'Invalid or missing token' }, status: :unauthorized
    end
  end
end
