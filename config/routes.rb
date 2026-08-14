# frozen_string_literal: true

module RegexDojo
  class Routes < Hanami::Routes
    root to: "inicio.show"

    get "/desafios", to: "desafios.index"
    get "/desafios/:id", to: "desafios.show"
    post "/desafios/:id/check", to: "challenges.check"
    get "/sandbox", to: "sandbox.show"
    get "/blitz", to: "blitz.show"
    post "/blitz/score", to: "blitz.score"
    get "/codex", to: "codex.show"
    get "/ruby", to: "ruby.index"
    get "/ruby/:id", to: "ruby.show"
    post "/ruby/:id/check", to: "challenges.check"
  end
end
