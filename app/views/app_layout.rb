# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Views
    # Document shell for the Organic screens: Portuguese lang, Organic fonts,
    # theme attribute from the server-read cookie, and the global header.
    # The legacy Views::Layout keeps serving the old dashboard until the
    # final swap deletes it.
    class AppLayout < Phlex::HTML
      include Translatable

      def initialize(user:, dark: false, csrf_token: nil, title: nil)
        @user = user
        @dark = dark
        @csrf_token = csrf_token
        @title = title
      end

      def view_template(&block)
        doctype

        html(**html_attributes) do
          head do
            meta(charset: "utf-8")
            meta(name: "viewport", content: "width=device-width, initial-scale=1")
            meta(name: "csrf-token", content: @csrf_token) if @csrf_token
            title { @title || t("app.title") }

            link(rel: "preconnect", href: "https://fonts.googleapis.com")
            link(rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: true)
            link(
              href: "https://fonts.googleapis.com/css2?family=Caprasimo&family=Figtree:wght@400;600;700&family=IBM+Plex+Mono:wght@400;500;600&display=swap",
              rel: "stylesheet"
            )

            link(rel: "stylesheet", href: "/assets/app.css")
            script(src: "/assets/app.js", defer: true)
          end

          body(class: "min-h-screen antialiased text-[15px] leading-relaxed") do
            render Components::Header.new(user: @user, dark: @dark)
            yield(self) if block
          end
        end
      end

      private

      def html_attributes
        # The `organic` class scopes the migration-bridge CSS; data-dark is
        # stamped server-side so the first paint carries the right theme.
        attrs = {lang: "pt-BR", class: "organic"}
        attrs[:"data-dark"] = "" if @dark
        attrs
      end
    end
  end
end
