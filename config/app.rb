# frozen_string_literal: true

require "hanami"

module RegexDojo
  class App < Hanami::App
    config.actions.sessions = :cookie, {
      key: "regex_dojo.session",
      secret: ENV.fetch("SESSION_SECRET") {
        raise "SESSION_SECRET must be set in production" if Hanami.env?(:production)

        # Deterministic fallback so dev/test sessions survive restarts
        "dev-only-insecure-secret-#{"a" * 40}"
      },
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
