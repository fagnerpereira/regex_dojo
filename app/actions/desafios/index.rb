# frozen_string_literal: true

module RegexDojo
  module Actions
    module Desafios
      # /desafios lands on the first unsolved challenge (wrapping to the
      # first once everything is solved) — same selection the home hero uses.
      class Index < RegexDojo::Action
        include Deps["repos.dojo_repo"]

        def handle(request, response)
          user = current_user(request)
          track = dojo_repo.next_challenge_for(user.id, track: "regex")

          response.redirect_to("/desafios/#{track[:challenge].id}")
        end
      end
    end
  end
end
