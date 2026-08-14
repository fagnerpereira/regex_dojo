# frozen_string_literal: true

module RegexDojo
  module Actions
    module Sandbox
      class Show < RegexDojo::Action
        include Deps["repos.dojo_repo"]

        def handle(request, response)
          user = current_user(request)

          view = Views::Sandbox::Show.new(pattern: request.params[:pattern])
          render_page(request, response, user: user, view: view)
        end
      end
    end
  end
end
