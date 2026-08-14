# frozen_string_literal: true

module RegexDojo
  module Actions
    module Ruby
      class Show < RegexDojo::Action
        include Deps["repos.dojo_repo"]

        def handle(request, response)
          user = current_user(request)

          rows = dojo_repo.all_challenges(track: "ruby")
          index = rows.index { |c| c.id.to_s == request.params[:id].to_s }
          halt 404 unless index

          solved_ids = dojo_repo.get_user_progress(user.id)
            .select { |p| p.solved }
            .map { |p| p.kata_id }

          challenge = rows[index]

          view = Views::Ruby::Show.new(
            challenge: challenge,
            position: index + 1,
            total: rows.size,
            previous_id: rows[(index - 1) % rows.size].id,
            next_id: rows[(index + 1) % rows.size].id,
            solved: solved_ids.include?(challenge.id.to_s),
            last_answer: dojo_repo.latest_patterns_for_user(user.id)[challenge.id.to_s],
            result: request.flash[:challenge_result]
          )

          render_page(request, response, user: user, view: view)
        end
      end
    end
  end
end
