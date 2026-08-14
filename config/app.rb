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

    # Hanami's default CSP restricts fonts to 'self', but the layout loads
    # Google Fonts — allow the font files it serves from fonts.gstatic.com.
    config.actions.content_security_policy[:font_src] += " https://fonts.gstatic.com"

    # Serve static assets from public/ ourselves. Hanami's implicit assets
    # middleware (mounted ahead of user middleware when assets.serve is true)
    # takes no options, and the asset paths here are unfingerprinted — so we
    # disable it and serve with a forced-revalidation policy (304s when
    # unchanged). Otherwise browsers heuristically cache the assets and every
    # CSS/JS change silently requires a hard refresh.
    config.assets.serve = false
    require "rack/static"
    config.middleware.use Rack::Static, {
      urls: ["/assets"],
      root: File.join(__dir__, "..", "public"),
      header_rules: [[:all, {"cache-control" => "no-cache"}]]
    }
  end
end
