# frozen_string_literal: true

require "phlex"

module RegexDojo
  module Views
    module Components
      # Inline Lucide icons (stroke 2.75) copied from the Organic prototype.
      # The registry is static trusted markup, rendered raw so components
      # don't depend on Phlex's SVG element DSL.
      class Icon < Phlex::HTML
        PATHS = {
          moon: %(<path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"/>),
          sun: %(<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>),
          flame: %(<path d="M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z"/>),
          chevron_down: %(<path d="m6 9 6 6 6-6"/>),
          chevron_right: %(<path d="m9 18 6-6-6-6"/>),
          arrow_left: %(<path d="m12 19-7-7 7-7M19 12H5"/>),
          check: %(<path d="M20 6 9 17l-5-5"/>),
          info: %(<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>),
          copy: %(<rect width="14" height="14" x="8" y="8" rx="3"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/>),
          flask: %(<path d="M14 2v6l4.5 8.5A2 2 0 0 1 16.7 20H7.3a2 2 0 0 1-1.8-3.5L10 8V2"/><path d="M8.5 2h7"/><path d="M7 16h10"/>),
          zap: %(<path d="M13 2 3 14h9l-1 8 10-12h-9l1-8z"/>),
          book: %(<path d="M12 7v14"/><path d="M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z"/>)
        }.freeze

        def initialize(name, classes: "w-4 h-4")
          @name = name
          @classes = classes
        end

        def view_template
          raw safe(
            %(<svg class="#{@classes}" viewBox="0 0 24 24" fill="none" stroke="currentColor" ) +
              %(stroke-width="2.75" stroke-linecap="round" stroke-linejoin="round">#{PATHS.fetch(@name)}</svg>)
          )
        end
      end
    end
  end
end
