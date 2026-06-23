# frozen_string_literal: true

module RegexDojo
  class Routes < Hanami::Routes
    root to: "home.index"
    post "/kata/:id/check", to: "kata.check"
  end
end
