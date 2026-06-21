require 'net/http'
require 'uri'
require 'json'

def handler(event:, context:)
  user_attrs = event.dig('request', 'userAttributes') || {}

  uri = URI.parse("#{ENV['RAILS_API_URL']}/api/v1/sync_user")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.open_timeout = 5
  http.read_timeout = 10

  req = Net::HTTP::Post.new(uri.request_uri)
  req['Content-Type'] = 'application/json'
  req.body = JSON.generate({
    cognito_sub: user_attrs['sub'],
    email:       user_attrs['email'],
    nickname:    user_attrs['nickname']
  })

  res = http.request(req)
  puts "sync_user: #{res.code} #{res.body}"

  event
rescue => e
  puts "sync_user error: #{e.message}"
  event
end
