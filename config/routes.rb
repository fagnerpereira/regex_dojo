# frozen_string_literal: true

module RegexDojo
  class Routes < Hanami::Routes
    root to: "home.index"
    post "/kata/:id/check", to: "kata.check"

    # Organic screens (the root swaps to inicio.show once the old dashboard
    # retires; /inicio is its temporary address during the migration).
    get "/inicio", to: "inicio.show"
  end
end
