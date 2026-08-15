# frozen_string_literal: true

module RegexDojo
  module Actions
    module Ruby
      # /ruby lands on the learner's current challenge (first unsolved,
      # wrapping to the first once everything is solved).
      class Index < RegexDojo::Action
        include Deps["repos.dojo_repo"]

        def handle(request, response)
          user = current_user(request)
          track = dojo_repo.next_challenge_for(user.id, track: "ruby")

          response.redirect_to("/ruby/#{track[:challenge].id}")
        end
      end
    end
  end
end
