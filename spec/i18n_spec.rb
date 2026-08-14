# frozen_string_literal: true

require "spec_helper"
require "yaml"

# The pt and en locale files must stay in step so the future locale switcher
# never renders "translation missing".
RSpec.describe "Locale files" do
  def flatten_keys(hash, prefix = [])
    hash.flat_map do |key, value|
      path = prefix + [key]
      value.is_a?(Hash) ? flatten_keys(value, path) : [path.join(".")]
    end
  end

  it "keeps pt and en key sets identical" do
    pt = YAML.load_file(Hanami.app.root.join("config", "i18n", "pt.yml")).fetch("pt")
    en = YAML.load_file(Hanami.app.root.join("config", "i18n", "en.yml")).fetch("en")

    pt_keys = flatten_keys(pt).reject { |k| k.start_with?("date.") }
    en_keys = flatten_keys(en).reject { |k| k.start_with?("date.") }

    expect(pt_keys.sort).to eq(en_keys.sort)
  end
end
