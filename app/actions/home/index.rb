# frozen_string_literal: true

require "securerandom"
require_relative "../../../lib/regex_dojo/kata_pool"

module RegexDojo
  module Actions
    module Home
      class Index < RegexDojo::Action
        include Deps["repos.dojo_repo"]

        def handle(request, response)
          # Manage anonymous guest session
          session_id = request.session[:session_id] || request.session["session_id"]

          unless session_id
            session_id = SecureRandom.uuid
            request.session["session_id"] = session_id
          end

          # Find or create user
          user = dojo_repo.find_user_by_session_id(session_id)
          unless user
            dojo_repo.create_user(session_id: session_id)
            user = dojo_repo.find_user_by_session_id(session_id)
          end

          # Load user progress to mark solved katas
          solved_katas = dojo_repo.get_user_progress(user.id)
            .select { |p| p.solved }
            .map { |p| p.kata_id }

          # Load challenges from database
          challenges = dojo_repo.get_challenges_for_view
          blitz_challenges = dojo_repo.get_blitz_challenges_for_view

          # Render the full Phlex page
          layout = Views::Layout.new
          dashboard = Views::Home::Dashboard.new(
            user: user,
            solved_kata_ids: solved_katas,
            challenges: challenges,
            blitz_challenges: blitz_challenges
          )

          html = layout.call do |l|
            dashboard.call
          end

          response.body = html
          response.format = :html
        end
      end
    end
  end
end
