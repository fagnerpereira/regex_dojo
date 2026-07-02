# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Views
    class Layout < Phlex::HTML
      def initialize(title: "🥋 RegexDojo — Gamified Regex Learning")
        @title = title
      end

      def view_template
        doctype

        html(lang: "en") do
          head do
            meta(charset: "utf-8")
            meta(name: "viewport", content: "width=device-width, initial-scale=1")
            title { @title }

            # Google Fonts: Inter for UI, JetBrains Mono for Code
            link(rel: "preconnect", href: "https://fonts.googleapis.com")
            link(rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: true)
            link(href: "https://fonts.googleapis.com/css2?family=Baloo+2:wght@500;600;700;800&family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;700&display=swap", rel: "stylesheet")

            # Tailwind compiled CSS and JavaScript bundle
            link(rel: "stylesheet", href: "/assets/app.css")
            script(src: "/assets/app.js", defer: true)
          end

          body(class: "font-sans min-h-screen flex flex-col antialiased") do
            main(class: "flex-1 flex flex-col") { yield }
          end
        end
      end
    end
  end
end
