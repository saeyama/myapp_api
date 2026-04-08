# frozen_string_literal: true

require 'jwt'
require 'net/http'

class CognitoJwtVerifier
  def self.verify(token)
    region = ENV['AWS_REGION']
    user_pool_id = ENV['COGNITO_USER_POOL_ID']
    jwks_url = "https://cognito-idp.#{region}.amazonaws.com/#{user_pool_id}/.well-known/jwks.json"

    # Railsのキャッシュ機能で公開鍵を1時間記憶する
    jwks_hash = Rails.cache.fetch("cognito_jwks", expires_in: 1.hour) do
      jwks_response = Net::HTTP.get(URI(jwks_url))
      JSON.parse(jwks_response, symbolize_names: true)
    end

    begin
      decoded_token = JWT.decode(
        token, 
        nil, 
        true,
        { 
          algorithms: ['RS256'], 
          jwks: jwks_hash 
        }
      )
      
      return decoded_token.first
    rescue JWT::DecodeError => e
      Rails.logger.error("JWT Decode Error: #{e.message}")
      return nil
    end
  end
end
