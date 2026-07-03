module Screens
  # Playground — the ONE screen with real client-side interactivity.
  # All matching happens in the browser (no server round-trip needed),
  # via the Stimulus controller in stimulus/regex_playground_controller.js.
  class Playground < Phlex::HTML
    DEFAULT_PATTERN = '#([a-f0-9]{6}|[a-f0-9]{3})\\b'
    DEFAULT_FLAGS = "gi"
    DEFAULT_TEST = "bg: #fff; color: #1c1830;\nborder: #7c3aed; shadow: #ggg999;\naccent: #f59e0b; text: #211b3a"

    def view_template
      render UI::Card.new(data: {controller: "regex-playground"}) do
        topbar
        div(class: "flex flex-col lg:flex-row") do
          editor_column
          matches_column
        end
      end
    end

    private

    def topbar
      div(class: "flex items-center justify-between h-[66px] px-6 bg-white border-b border-dojo-violet-border") do
        div(class: "flex items-center gap-2.5 font-display font-extrabold text-lg") { "Playground" }
        div(class: "flex gap-2") do
          render UI::Button.new(variant: :ghost, data: {action: "regex-playground#reset"}) { "↺ Reset" }
          render UI::Button.new { "Run tests" }
        end
      end
    end

    def editor_column
      div(class: "flex-1 p-6 border-r border-dojo-violet-border") do
        div(class: "flex justify-between items-center mb-3") do
          span(class: "text-xs font-bold text-dojo-slate") { "PATTERN" }
          div(class: "flex gap-1.5", data: {regex_playground_target: "flags"}) do
            flag_pill("g")
            flag_pill("i")
            flag_pill("m")
          end
        end

        div(class: "bg-dojo-editor-bg rounded-2xl px-4.5 py-4 font-mono text-base text-dojo-editor-text flex items-center gap-0.5 mb-2") do
          span(class: "text-violet-300/70") { "/" }
          input(
            type: "text",
            class: "flex-1 bg-transparent border-0 outline-none text-dojo-editor-text font-mono min-w-0",
            value: DEFAULT_PATTERN,
            spellcheck: "false",
            data: {regex_playground_target: "pattern", action: "input->regex-playground#run"}
          )
          span(class: "text-violet-300/70") { "/" }
          span(class: "text-pink-400", data: {regex_playground_target: "flagsLabel"}) { DEFAULT_FLAGS }
        end

        # Error banner — hidden by default, shown by the Stimulus controller on invalid regex
        div(
          class: "hidden -mt-1 mb-4 px-3.5 py-2.5 bg-dojo-danger-bg border border-dojo-danger-border rounded-xl text-dojo-danger-text text-xs font-semibold font-mono",
          data: {regex_playground_target: "error"}
        )

        label(class: "text-xs font-bold text-dojo-slate") { "TEST STRING" }
        textarea(
          class: "w-full mt-2.5 bg-dojo-violet-wash border border-dojo-violet-border rounded-2xl p-4 text-sm text-dojo-ink font-mono leading-relaxed min-h-[110px] outline-none resize-y",
          spellcheck: "false",
          data: {regex_playground_target: "testString", action: "input->regex-playground#run"}
        ) { DEFAULT_TEST }

        label(class: "text-xs font-bold text-dojo-slate block mt-4.5") { "LIVE PREVIEW" }
        div(
          class: "mt-2.5 bg-dojo-violet-wash border border-dojo-violet-border rounded-xl px-3.5 py-3 text-[13.5px] text-dojo-ink font-mono leading-relaxed whitespace-pre-wrap break-words max-h-24 overflow-auto",
          data: {regex_playground_target: "preview"}
        )
      end
    end

    def matches_column
      div(class: "w-full lg:w-[360px] p-6 bg-dojo-violet-wash") do
        div(class: "flex justify-between items-center mb-3.5") do
          span(class: "text-xs font-bold text-dojo-slate") { "MATCHES" }
          span(
            class: "inline-flex items-center rounded-full px-2.5 py-1 text-[11.5px] font-bold bg-dojo-success-bg text-dojo-success-text",
            data: {regex_playground_target: "matchBadge"}
          )
        end
        div(class: "flex flex-col gap-2 max-h-72 overflow-auto", data: {regex_playground_target: "matchList"})
        div(
          class: "hidden mt-4 p-3.5 bg-dojo-success-bg border border-green-200 rounded-xl text-[12.5px] text-dojo-success-text font-semibold",
          data: {regex_playground_target: "successBanner"}
        )
      end
    end

    def flag_pill(flag)
      span(
        class: "inline-flex items-center rounded-full px-2.5 py-1 text-[11.5px] font-bold font-mono cursor-pointer bg-dojo-violet text-white",
        data: {flag: flag, action: "click->regex-playground#toggleFlag"}
      ) { flag }
    end
  end
end
