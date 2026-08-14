# auto_register: false
# frozen_string_literal: true

require "hanami/action"
require "dry/monads"
require "securerandom"

module RegexDojo
  class Action < Hanami::Action
    # Provide `Success` and `Failure` for pattern matching on operation results
    include Dry::Monads[:result]

    private

    # Guest identity: find or create the user tied to the cookie session,
    # minting a session id on first contact. Callers must inject
    # Deps["repos.dojo_repo"].
    def current_user(request)
      session_id = request.session[:session_id] || request.session["session_id"]

      unless session_id
        session_id = SecureRandom.uuid
        request.session["session_id"] = session_id
      end

      dojo_repo.find_user_by_session_id(session_id) || create_guest(session_id)
    end

    def create_guest(session_id)
      dojo_repo.create_user(session_id: session_id)
      dojo_repo.find_user_by_session_id(session_id)
    rescue ROM::SQL::UniqueConstraintError
      # Concurrent first requests raced on the unique session_id index.
      dojo_repo.find_user_by_session_id(session_id)
    end

    # The theme cookie is written client-side by the theme toggle and only
    # read here, so the very first paint carries the right html[data-dark].
    def dark_mode?(response)
      response.cookies[:theme] == "dark"
    end

    # hanami-action's set_csrf_token callback populates this key on every
    # request outside the test env; ||= keeps request specs working there.
    def csrf_token(request)
      request.session[:_csrf_token] ||= SecureRandom.hex(32)
    end

    # Standard render path for the Organic screens: page component inside
    # Views::AppLayout with the shared header, theme and CSRF wiring.
    def render_page(request, response, user:, view:, title: nil)
      layout = Views::AppLayout.new(
        user: user,
        dark: dark_mode?(response),
        csrf_token: csrf_token(request),
        title: title
      )

      response.body = layout.call { |l| l.render(view) }
      response.format = :html
    end
  end
end
