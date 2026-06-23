# frozen_string_literal: true

require "hanami"

module RegexDojo
  class App < Hanami::App
    config.actions.sessions = :cookie, {
      key: "regex_dojo.session",
      secret: ENV.fetch("SESSION_SECRET", "a" * 64),
      expire_after: 60 * 60 * 24 * 30 # 30 days
    }

    # Allow serving static assets from public/
    require "rack/static"
    config.middleware.use Rack::Static, {
      urls: ["/assets"],
      root: File.join(__dir__, "..", "public")
    }
  end
end
