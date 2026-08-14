# frozen_string_literal: true

module RegexDojo
  module Actions
    module Codex
      class Show < RegexDojo::Action
        include Deps["repos.dojo_repo"]

        def handle(request, response)
          user = current_user(request)

          render_page(request, response, user: user, view: Views::Codex::Show.new)
        end
      end
    end
  end
end
