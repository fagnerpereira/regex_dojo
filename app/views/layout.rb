# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Views
    class Layout < Phlex::HTML
      include Translatable

      def initialize(title: nil, csrf_token: nil)
        @title = title
        @csrf_token = csrf_token
      end

      def view_template(&block)
        doctype

        html(lang: "en") do
          head do
            meta(charset: "utf-8")
            meta(name: "viewport", content: "width=device-width, initial-scale=1")
            meta(name: "csrf-token", content: @csrf_token) if @csrf_token
            title { @title || t("app.title") }

            # Google Fonts: Inter for UI, JetBrains Mono for Code
            link(rel: "preconnect", href: "https://fonts.googleapis.com")
            link(rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: true)
            link(href: "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;700&display=swap", rel: "stylesheet")

            # Tailwind compiled CSS and JavaScript bundle
            link(rel: "stylesheet", href: "/assets/app.css")
            script(src: "/assets/app.js", defer: true)
          end

          body(class: "bg-dojo-bg text-white font-ui min-h-screen flex flex-col antialiased selection:bg-dojo-cyan/30 selection:text-dojo-cyan") do
            main(class: "flex-1 flex flex-col", &block)
          end
        end
      end
    end
  end
end
