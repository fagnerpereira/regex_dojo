# frozen_string_literal: true

module RegexDojo
  module Actions
    module Desafios
      class Show < RegexDojo::Action
        include Deps["repos.dojo_repo"]

        def handle(request, response)
          user = current_user(request)

          challenges = dojo_repo.get_challenges_for_view
          challenge = challenges.find { |c| c[:id] == request.params[:id].to_s }
          halt 404 unless challenge

          solved_ids = dojo_repo.get_user_progress(user.id)
            .select { |p| p.solved }
            .map { |p| p.kata_id }

          view = Views::Desafios::Show.new(
            challenge: challenge,
            challenges: challenges,
            solved_ids: solved_ids,
            last_pattern: dojo_repo.latest_patterns_for_user(user.id)[challenge[:id]],
            result: request.flash[:challenge_result]
          )

          render_page(request, response, user: user, view: view)
        end
      end
    end
  end
end
