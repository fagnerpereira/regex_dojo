# frozen_string_literal: true

require "json"

module RegexDojo
  module Actions
    module Blitz
      # Fire-and-forget persistence at the end of a run — the record lives in
      # the database (blitz_scores), not in the browser.
      class Score < RegexDojo::Action
        include Deps["repos.dojo_repo"]

        def handle(request, response)
          user = current_user(request)
          payload = parse_body(request)
          score = payload[:score].to_i

          halt 422 if score.negative?

          dojo_repo.save_blitz_score(user.id, score, (payload[:speed_multiplier] || 1.0).to_f)

          response.status = 204
          response.body = ""
        end

        private

        def parse_body(request)
          JSON.parse(request.body.read, symbolize_names: true)
        rescue JSON::ParserError
          {}
        end
      end
    end
  end
end
