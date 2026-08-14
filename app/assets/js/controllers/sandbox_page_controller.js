import { Controller } from "@hotwired/stimulus";
import { PatternField } from "../lib/pattern_field";
import { escapeHTML, markAll, markFirst } from "../lib/highlight";
import { explanationHTML } from "../lib/explanation";

// The Organic Sandbox page. With the g flag every occurrence is marked and
// counted; without it only the first. Registered as "sandbox-page" while the
// legacy dashboard still owns the "sandbox" name; the final swap renames it.
//
// innerHTML sinks only receive escapeHTML-built strings.
export default class extends Controller {
  static targets = [
    "field",
    "fieldHighlight",
    "flagButton",
    "flagsText",
    "tokens",
    "text",
    "output",
    "count",
    "copyLabel",
  ];

  connect() {
    this.patternField = new PatternField({
      textarea: this.fieldTarget,
      highlight: this.fieldHighlightTarget,
      flagButtons: this.flagButtonTargets,
      flagsText: this.hasFlagsTextTarget ? this.flagsTextTarget : null,
      onChange: () => this.evaluate(),
    });

    this.evaluate();
  }

  disconnect() {
    this.patternField?.destroy();
  }

  evaluate() {
    const pattern = this.patternField.pattern;
    const flags = this.patternField.flagString;
    this.tokensTarget.innerHTML = explanationHTML(
      pattern,
      this.patternField.flags,
      "digite um padrão para ver a explicação"
    );

    const text = this.textTarget.value;
    let regex = null;
    try {
      if (pattern) regex = new RegExp(pattern, flags);
    } catch (_) {
      regex = null;
    }

    if (!regex) {
      this.outputTarget.innerHTML = escapeHTML(text) || "&nbsp;";
      this.countTarget.textContent = pattern ? "padrão inválido ou incompleto" : this.occurrences(0);
      return;
    }

    if (flags.includes("g")) {
      const { html, count } = markAll(text, regex);
      this.outputTarget.innerHTML = html || "&nbsp;";
      this.countTarget.textContent = this.occurrences(count);
    } else {
      const match = text.match(regex);
      this.outputTarget.innerHTML = markFirst(text, match) || "&nbsp;";
      this.countTarget.textContent = this.occurrences(match && match[0] ? 1 : 0);
    }
  }

  copyText() {
    navigator.clipboard.writeText(this.textTarget.value);
    this.copyLabelTarget.textContent = "copiado!";
    setTimeout(() => {
      this.copyLabelTarget.textContent = "copiar";
    }, 1200);
  }

  occurrences(count) {
    return `${count} ${count === 1 ? "ocorrência" : "ocorrências"}`;
  }
}
