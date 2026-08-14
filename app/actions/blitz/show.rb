# frozen_string_literal: true

module RegexDojo
  module Actions
    module Blitz
      class Show < RegexDojo::Action
        include Deps["repos.dojo_repo"]

        def handle(request, response)
          user = current_user(request)

          view = Views::Blitz::Show.new(
            challenges: dojo_repo.get_blitz_challenges_for_view,
            best_score: dojo_repo.best_blitz_score(user.id)
          )

          render_page(request, response, user: user, view: view)
        end
      end
    end
  end
end
