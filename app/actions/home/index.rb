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
          solved_kata_ids = dojo_repo.get_user_progress(user.id)
            .select { |p| p.solved }
            .map { |p| p.kata_id }

          # Load challenges from database
          challenges = dojo_repo.get_challenges_for_view

          # Calculate belt progress percentage
          xp = user.xp
          belt_percent = if xp >= 370
            100
          elsif xp >= 265
            (((xp - 265) / 105.0) * 100).round
          elsif xp >= 160
            (((xp - 160) / 105.0) * 100).round
          elsif xp >= 75
            (((xp - 75) / 85.0) * 100).round
          else
            ((xp / 75.0) * 100).round
          end
          belt_percent = belt_percent.clamp(0, 100)

          # Calculate submission accuracy
          total_subs = dojo_repo.submissions.count
          passing_subs = dojo_repo.submissions.where(is_passing: true).count
          accuracy = (total_subs > 0) ? ((passing_subs.to_f / total_subs) * 100).round : 100

          # User rank on the leaderboard
          rank = dojo_repo.users.where { xp > user.xp }.count + 1

          # Wrap user model in a presenter struct
          user_presenter = Struct.new(
            :id, :session_id, :xp, :belt, :streak, :katas_solved, :accuracy, :rank, :belt_percent, :initials
          ).new(
            user.id,
            user.session_id,
            user.xp,
            user.belt,
            user.streak,
            solved_kata_ids.size,
            accuracy,
            rank,
            belt_percent,
            user.session_id[0..1].upcase
          )

          # Query top users for leaderboard
          top_users = dojo_repo.top_users(10)

          # Render the full Phlex page
          layout = Views::Layout.new
          dashboard = Components::Screens::AppShell.new(
            user: user_presenter,
            top_users: top_users,
            challenges: challenges,
            solved_kata_ids: solved_kata_ids
          )

          # Render the dashboard *into* the layout's buffer. `render` writes
          # directly (returns nil) — returning a string here would be escaped.
          html = layout.call do |l|
            l.render(dashboard)
          end

          response.body = html
          response.format = :html
        end
      end
    end
  end
end
