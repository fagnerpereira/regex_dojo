# frozen_string_literal: true

module RegexDojo
  module Actions
    module Inicio
      class Show < RegexDojo::Action
        include Deps["repos.dojo_repo"]

        def handle(request, response)
          user = current_user(request)

          solved_ids = dojo_repo.get_user_progress(user.id)
            .select { |p| p.solved }
            .map { |p| p.kata_id }

          challenges = dojo_repo.get_challenges_for_view
          ruby_track = dojo_repo.next_challenge_for(user.id, track: "ruby")

          view = Views::Inicio::Show.new(
            user: user,
            challenges: challenges,
            solved_ids: solved_ids,
            ruby_track: ruby_track
          )

          render_page(request, response, user: user, view: view)
        end
      end
    end
  end
end
