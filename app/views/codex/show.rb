# auto_register: false
# frozen_string_literal: true

# Kept out of the container so Actions::Codex::Show doesn't auto-pair with
# it; the action builds this Phlex page by hand.

require "phlex"
require "cgi"

module RegexDojo
  module Views
    module Codex
      # The complete reference in cards per group. Every card except the
      # Flags group is a plain link that opens its example in the Sandbox.
      class Show < Phlex::HTML
        include Views::Translatable

        # Reference data from the Organic prototype: token, label, example.
        SECTIONS = [
          ["Âncoras", [
            ["^", "início da linha", "^Hello"],
            ["$", "fim da linha", "Dojo$"],
            ["\\b", "borda de palavra", "\\bcat\\b"],
            ["\\B", "não borda", "\\Bcat"]
          ]],
          ["Classes", [
            ["[abc]", "um dos listados", "b[ae]t"],
            ["[^abc]", "negação", "[^n]ot"],
            ["[a-z]", "intervalo", "[p-s]"],
            [".", "qualquer caractere", "c.t"],
            ["\\d", "dígito", "\\d{3}"],
            ["\\D", "não dígito", "\\D+"],
            ["\\w", "caractere de palavra", "\\w+"],
            ["\\W", "não palavra", "\\W"],
            ["\\s", "espaço em branco", "a\\sb"],
            ["\\S", "não espaço", "\\S+"]
          ]],
          ["Quantificadores", [
            ["*", "zero ou mais", "ab*c"],
            ["+", "um ou mais", "ho+ray"],
            ["?", "opcional", "colou?r"],
            ["{n}", "exatamente n", "\\d{4}"],
            ["{n,m}", "de n a m", "\\w{2,5}"],
            ["{n,}", "n ou mais", "a{3,}"],
            ["*?", "lazy: o mínimo possível", "<.*?>"]
          ]],
          ["Grupos", [
            ["(abc)", "grupo de captura", "(\\d+)px"],
            ["(?:abc)", "grupo sem captura", "(?:ab)+"],
            ["(?<nome>)", "grupo nomeado", "(?<ano>\\d{4})"],
            ["|", "alternância (ou)", "cat|dog"],
            ["\\1", "backreference", "(\\w)\\1"]
          ]],
          ["Lookaround", [
            ["(?=…)", "lookahead", "\\d+(?=px)"],
            ["(?!…)", "lookahead negativo", "\\bcat(?!s)"],
            ["(?<=…)", "lookbehind", "(?<=R\\$)\\d+"],
            ["(?<!…)", "lookbehind negativo", "(?<!-)\\d+"]
          ]],
          ["Flags", [
            ["g", "todas as ocorrências", "/cat/g"],
            ["i", "ignora maiúsculas", "/hello/i"],
            ["m", "multilinha", "/^linha/m"],
            ["s", "ponto casa quebra de linha", "/a.b/s"]
          ]]
        ].freeze

        NON_CLICKABLE_GROUPS = ["Flags"].freeze

        def view_template
          main(class: "max-w-[1040px] mx-auto px-11 pb-24 max-md:px-6") do
            top_line

            header(class: "mt-7 mb-2") do
              h1(class: "font-display text-[40px] leading-[1.1]") { "Codex" }
              p(class: "opacity-70 mt-1.5") { t("codex.subtitle") }
            end

            SECTIONS.each { |name, entries| section_block(name, entries) }
          end
        end

        private

        def top_line
          div(class: "flex items-center gap-4 py-1") do
            a(class: "btn btn-ghost text-[14px]", href: "/") do
              render Components::Icon.new(:arrow_left)
              plain t("desafio.back")
            end
            span(class: "mx-auto font-mono text-[12.5px] text-ink/55") { t("codex.context") }
            span(class: "w-[76px]")
          end
        end

        def section_block(name, entries)
          h6(class: "font-body text-[13px] uppercase tracking-[0.08em] text-ink/50 font-semibold mt-9 mb-3") do
            name
          end
          div(class: "grid grid-cols-3 gap-3 max-lg:grid-cols-2 max-md:grid-cols-1") do
            entries.each { |entry| card(entry, clickable: !NON_CLICKABLE_GROUPS.include?(name)) }
          end
        end

        def card(entry, clickable:)
          token, label, example = entry

          if clickable
            a(
              href: "/sandbox?pattern=#{CGI.escape(example)}",
              class: "bg-dune-100 rounded-2xl px-4 py-3.5 text-left flex flex-col gap-1 no-underline text-ink hover:bg-terra-100 transition-colors"
            ) { card_body(token, label, example) }
          else
            div(class: "bg-dune-100 rounded-2xl px-4 py-3.5 flex flex-col gap-1") do
              card_body(token, label, example)
            end
          end
        end

        def card_body(token, label, example)
          span(class: "font-mono text-[16px] font-medium text-terra-700") { token }
          span(class: "text-[13px]") { label }
          span(class: "font-mono text-[11.5px] opacity-55") { example }
        end
      end
    end
  end
end
