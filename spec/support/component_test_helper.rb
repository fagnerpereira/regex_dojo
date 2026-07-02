# frozen_string_literal: true

require "nokogiri"

# Phlex 2.x components are rendered standalone via `#call`, per
# https://www.phlex.fun/components/testing.html — `render_fragment` parses
# the output with Nokogiri so specs can assert with CSS selectors instead of
# fragile string matching.
module ComponentTestHelper
  def render(component)
    component.call
  end

  def render_fragment(component)
    Nokogiri::HTML5.fragment(render(component))
  end
end

RSpec.configure do |config|
  config.include ComponentTestHelper, type: :component
end
