# frozen_string_literal: true

require "spec_helper"
require "i18n"

RSpec.describe "RegexDojo::Views::Translatable" do
  let(:host) do
    Class.new do
      include RegexDojo::Views::Translatable

      def title = t("app.title")

      def greeting(date) = l(date, format: :greeting)
    end.new
  end

  it "resolves keys through the app's i18n provider (default locale pt)" do
    expect(host.title).to eq("Regex Dojo")
  end

  it "localizes dates with the Portuguese calendar" do
    expect(host.greeting(Date.new(2026, 8, 14))).to eq("sexta-feira, 14 de agosto")
  end

  it "raises on missing keys instead of rendering a placeholder" do
    expect {
      host.instance_eval { t!("nope.missing.key") }
    }.to raise_error(I18n::MissingTranslationData)
  end
end
