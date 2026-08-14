import { Controller } from "@hotwired/stimulus";
import { PatternField } from "../lib/pattern_field";
import { gradeTestCase } from "../lib/grading";
import { escapeHTML, markFirst } from "../lib/highlight";
import { explanationHTML } from "../lib/explanation";

// The Desafio screen: live evaluation on every keystroke against the
// challenge's test cases (mirroring the server rule via lib/grading), the
// clickable token explanation, and the 3-layer hint. Submission is a real
// form POST — the server grades, awards XP and redirects back (PRG), so
// nothing here patches XP, banners or dots.
//
// All rendered fragments below are built from escapeHTML-processed strings,
// so assigning them via innerHTML cannot inject markup.
export default class extends Controller {
  static targets = [
    "form",
    "field",
    "fieldHighlight",
    "flagButton",
    "flagsText",
    "testsList",
    "tokens",
    "hintBox",
    "submit",
  ];

  static values = { tests: Array, hints: Array, lastPattern: String };

  connect() {
    this.hintLevel = 0;

    this.patternField = new PatternField({
      textarea: this.fieldTarget,
      highlight: this.fieldHighlightTarget,
      flagButtons: this.flagButtonTargets,
      flagsText: this.hasFlagsTextTarget ? this.flagsTextTarget : null,
      onChange: () => this.evaluate(),
      onSubmit: () => this.submitNow(),
    });

    if (this.lastPatternValue) this.patternField.setValue(this.lastPatternValue);
    this.evaluate();
    this.patternField.focus();
  }

  disconnect() {
    this.patternField?.destroy();
  }

  // Enter always submits a non-empty pattern — even a failing one — so every
  // explicit attempt reaches the server and submission history stays
  // complete. Only the Enviar button is gated on all tests passing.
  submitNow() {
    if (!this.patternField.pattern.trim()) return;

    this.formTarget.requestSubmit();
  }

  revealHint() {
    const layers = this.hintsValue;
    if (!layers.length) return;

    this.hintLevel = Math.min(3, this.hintLevel + 1);
    const text = layers[Math.min(this.hintLevel, layers.length) - 1] ?? "";
    const revealed =
      this.hintLevel >= 3
        ? `Resposta: <span class="font-mono font-semibold">${escapeHTML(text)}</span>`
        : escapeHTML(text);

    this.hintBoxTarget.innerHTML = `${revealed} <span class="opacity-55">(${this.hintLevel}/3)</span>`;
    this.hintBoxTarget.classList.remove("hidden");
  }

  evaluate() {
    const pattern = this.patternField.pattern;
    this.renderTokens(pattern);

    // `g` is dropped for grading (like the prototype): String#match with a
    // global regex loses the capture groups the grading rule needs.
    const flags = this.patternField.flagString.replace("g", "");
    let regex = null;
    try {
      if (pattern) regex = new RegExp(pattern, flags);
    } catch (_) {
      regex = null;
    }

    let passCount = 0;
    this.testsListTarget.innerHTML = this.testsValue
      .map((testCase) => {
        const ok = Boolean(pattern) && gradeTestCase(pattern, flags, testCase);
        if (ok) passCount++;

        const match = regex ? testCase.input.match(regex) : null;
        return this.testRow(testCase, match, ok);
      })
      .join("");

    const allPass = passCount === this.testsValue.length && Boolean(pattern);
    this.submitTarget.disabled = !allPass;
  }

  testRow(testCase, match, ok) {
    const shown = markFirst(testCase.input, match);
    const expectation =
      testCase.expected_match != null
        ? `deve combinar "${escapeHTML(testCase.expected_match)}"`
        : "não deve combinar";
    const status = ok
      ? '<svg class="w-4 h-4 shrink-0 text-sage-700" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.75" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>'
      : '<span class="w-3 h-3 shrink-0 rounded-full border-[1.5px] border-ink/25"></span>';

    return (
      '<div class="flex items-center gap-3.5 rounded-2xl bg-dune-100 px-5 py-3">' +
      `<span class="font-mono text-[15px] flex-1">${shown}</span>` +
      `<span class="text-[11.5px] text-ink/45">${expectation}</span>` +
      status +
      "</div>"
    );
  }

  renderTokens(pattern) {
    this.tokensTarget.innerHTML = explanationHTML(
      pattern,
      this.patternField.flags,
      "digite para ver cada símbolo explicado"
    );
  }
}
