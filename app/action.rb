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
  end
end
