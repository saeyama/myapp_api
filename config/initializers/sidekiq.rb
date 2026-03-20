Sidekiq.configure_server do |config|
  # Docker内のサービス名「redis」を指定
  config.redis = { url: 'redis://redis:6379/1' }
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://redis:6379/1' }
end
