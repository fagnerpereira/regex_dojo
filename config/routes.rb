# frozen_string_literal: true

module RegexDojo
  class Routes < Hanami::Routes
    root to: "home.index"
    post "/kata/:id/check", to: "kata.check"

    # Organic screens (the root swaps to inicio.show once the old dashboard
    # retires; /inicio is its temporary address during the migration).
    get "/inicio", to: "inicio.show"
    get "/desafios", to: "desafios.index"
    get "/desafios/:id", to: "desafios.show"
    post "/desafios/:id/check", to: "challenges.check"
  end
end
