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

    # Per-request CSP nonce: the middleware injects a random nonce into the
    # response CSP header, and `content_security_policy_nonce` exposes it to views.
    config.middleware.use Hanami::Middleware::ContentSecurityPolicyNonce
    config.actions.content_security_policy[:script_src] += " 'nonce'"

    environment(:development) do
      config.logger.stream = root.join("log").join("development.log")
    end
  end
end
