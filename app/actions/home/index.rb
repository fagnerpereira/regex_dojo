# frozen_string_literal: true

require "securerandom"

module RegexDojo
  module Actions
    module Home
      class Index < RegexDojo::Action
        include Deps["repos.dojo_repo"]

        def handle(request, response)
          # Find or create the anonymous guest user for this session
          user = current_user(request)

          # Load user progress to mark solved katas
          solved_katas = dojo_repo.get_user_progress(user.id)
            .select { |p| p.solved }
            .map { |p| p.kata_id }

          # Load challenges once; blitz is the same list minus hard katas
          challenges = dojo_repo.get_challenges_for_view
          blitz_challenges = challenges.reject { |c| c[:difficulty].to_s.downcase == "hard" }

          # The learner's latest answer per kata, restored into the pattern input
          last_patterns = dojo_repo.latest_patterns_for_user(user.id)

          # The ruby track shows one server-selected challenge at a time;
          # ruby_after/ruby_before come from the panel's next/previous links.
          # Those are full navigations, so the server also pins the landing
          # tab — the client's localStorage restore can't be relied on
          # (private browsing).
          ruby_after = request.params[:ruby_after]
          ruby_before = request.params[:ruby_before]
          ruby_track = dojo_repo.next_challenge_for(
            user.id, track: "ruby", after: ruby_after, before: ruby_before
          )
          active_tab = (ruby_after || ruby_before) ? "ruby" : nil

          # Render the full Phlex page.
          # hanami-action's set_csrf_token callback populates this key on every
          # request outside the test env; ||= keeps request specs working there.
          csrf_token = (request.session[:_csrf_token] ||= SecureRandom.hex(32))

          layout = Views::Layout.new(csrf_token: csrf_token)
          dashboard = Views::Home::Dashboard.new(
            user: user,
            solved_kata_ids: solved_katas,
            challenges: challenges,
            blitz_challenges: blitz_challenges,
            last_patterns: last_patterns,
            ruby_track: ruby_track,
            active_tab: active_tab
          )

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
