# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Views
    module Components
      class CodexPanel < Phlex::HTML
        SECTIONS = [
          {
            title: "🎯 Anchors",
            color: "dojo-pink",
            items: [
              {syntax: "^", name: "Line Start", desc: "Matches the beginning of a line", example: "^Hello"},
              {syntax: "$", name: "Line End", desc: "Matches the end of a line", example: "world$"},
              {syntax: "\\b", name: "Word Boundary", desc: "Matches boundary between word/non-word chars", example: "\\bcat\\b"},
              {syntax: "\\B", name: "Non-Boundary", desc: "Matches position that is NOT a word boundary", example: "\\Bcat\\B"}
            ]
          },
          {
            title: "📦 Character Classes",
            color: "dojo-cyan",
            items: [
              {syntax: "[abc]", name: "Character Set", desc: "Matches any character in the set", example: "[aeiou]"},
              {syntax: "[^abc]", name: "Negated Set", desc: "Matches any character NOT in the set", example: "[^0-9]"},
              {syntax: "[a-z]", name: "Range", desc: "Matches any character in the range", example: "[A-Za-z]"},
              {syntax: ".", name: "Wildcard", desc: "Matches any character except newline", example: "c.t"},
              {syntax: "\\d", name: "Digit", desc: "Matches any digit [0-9]", example: "\\d{3}"},
              {syntax: "\\w", name: "Word Char", desc: "Matches [a-zA-Z0-9_]", example: "\\w+"},
              {syntax: "\\s", name: "Whitespace", desc: "Matches spaces, tabs, newlines", example: "\\s+"},
              {syntax: "\\D", name: "Non-digit", desc: "Matches any non-digit character", example: "\\D+"},
              {syntax: "\\W", name: "Non-word", desc: "Matches any non-word character", example: "\\W"},
              {syntax: "\\S", name: "Non-space", desc: "Matches any non-whitespace character", example: "\\S+"}
            ]
          },
          {
            title: "🔢 Quantifiers",
            color: "dojo-gold",
            items: [
              {syntax: "*", name: "Zero or More", desc: "Matches 0+ repetitions (greedy)", example: "ab*c"},
              {syntax: "+", name: "One or More", desc: "Matches 1+ repetitions (greedy)", example: "go+al"},
              {syntax: "?", name: "Optional", desc: "Matches 0 or 1 time (greedy)", example: "colou?r"},
              {syntax: "{n}", name: "Exact Count", desc: "Matches exactly n times", example: "\\d{4}"},
              {syntax: "{n,m}", name: "Range Count", desc: "Matches between n and m times", example: "\\w{2,5}"},
              {syntax: "{n,}", name: "At Least n", desc: "Matches n or more times", example: "a{3,}"},
              {syntax: "*?", name: "Lazy Zero+", desc: "Matches 0+ (non-greedy/lazy)", example: "<.*?>"},
              {syntax: "+?", name: "Lazy One+", desc: "Matches 1+ (non-greedy/lazy)", example: "\\w+?"}
            ]
          },
          {
            title: "👥 Groups & Backreferences",
            color: "dojo-purple",
            items: [
              {syntax: "(abc)", name: "Capture Group", desc: "Captures matched text into a numbered group", example: "(\\d+)px"},
              {syntax: "(?:abc)", name: "Non-Capture", desc: "Groups without capturing", example: "(?:ab)+"},
              {syntax: "(?<name>)", name: "Named Group", desc: "Captures into a named group", example: "(?<year>\\d{4})"},
              {syntax: "|", name: "Alternation", desc: "Matches either left or right side", example: "cat|dog"},
              {syntax: "\\1", name: "Backreference", desc: "Matches same text as captured group 1", example: "(\\w)\\1"}
            ]
          },
          {
            title: "👀 Lookarounds",
            color: "dojo-green",
            items: [
              {syntax: "(?=...)", name: "Lookahead", desc: "Matches if followed by pattern", example: "\\d+(?=px)"},
              {syntax: "(?!...)", name: "Neg. Lookahead", desc: "Matches if NOT followed by pattern", example: "\\bcat(?!s)"},
              {syntax: "(?<=...)", name: "Lookbehind", desc: "Matches if preceded by pattern", example: "(?<=\\$)\\d+"},
              {syntax: "(?<!...)", name: "Neg. Lookbehind", desc: "Matches if NOT preceded by pattern", example: "(?<!-)\\d+"}
            ]
          },
          {
            title: "🏳️ Flags",
            color: "dojo-blue",
            items: [
              {syntax: "g", name: "Global", desc: "Match all occurrences, not just the first", example: "/cat/g"},
              {syntax: "i", name: "Case-Insensitive", desc: "Match regardless of letter case", example: "/hello/i"},
              {syntax: "m", name: "Multiline", desc: "^ and $ match start/end of each line", example: "/^line/m"},
              {syntax: "s", name: "Dotall", desc: "Makes . also match newline characters", example: "/a.b/s"}
            ]
          }
        ].freeze

        def view_template
          div(class: "flex flex-col gap-8") do
            # Header
            div do
              h2(class: "text-xl font-bold text-white") { "📖 Regex Codex" }
              p(class: "text-sm text-gray-400 mt-1") { "Complete reference guide. Click any example to try it in the Sandbox." }
            end

            SECTIONS.each do |section|
              div(class: "flex flex-col gap-3") do
                h3(class: "text-sm font-mono font-semibold uppercase tracking-wider text-#{section[:color]}") { section[:title] }

                div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3") do
                  section[:items].each do |item|
                    div(class: "codex-card", data: {action: "click->tabs#loadInSandbox", pattern: item[:example]}) do
                      div(class: "flex items-center justify-between mb-2") do
                        code { item[:syntax] }
                        span(class: "text-xs font-mono text-gray-500") { item[:name] }
                      end
                      p(class: "text-xs text-gray-400 leading-relaxed") { item[:desc] }
                      div(class: "mt-2 pt-2 border-t border-dojo-border") do
                        span(class: "text-[10px] font-mono text-gray-500") { "Example: " }
                        code(class: "text-[11px]") { item[:example] }
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
