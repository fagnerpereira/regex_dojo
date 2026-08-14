import { Controller } from "@hotwired/stimulus";

/**
 * SandboxController — free regex playground with live matching and
 * a visual pattern explainer.
 *
 * HTML contract:
 *   <div data-controller="sandbox">
 *     <input data-sandbox-target="pattern" data-action="input->sandbox#evaluate" />
 *     <textarea data-sandbox-target="input" data-action="input->sandbox#evaluate">...</textarea>
 *     <div data-sandbox-target="highlightArea"></div>
 *     <div data-sandbox-target="explainer"></div>
 *     <span data-sandbox-target="matchCount"></span>
 *     <span data-sandbox-target="flagsDisplay">/g</span>
 *     <button data-sandbox-target="flagG" data-flag="g" data-action="click->sandbox#toggleFlag">g</button>
 *     <button data-sandbox-target="flagI" data-flag="i" data-action="click->sandbox#toggleFlag">i</button>
 *     <button data-sandbox-target="flagM" data-flag="m" data-action="click->sandbox#toggleFlag">m</button>
 *     <button data-sandbox-target="flagS" data-flag="s" data-action="click->sandbox#toggleFlag">s</button>
 *     <button data-action="click->sandbox#clear">Clear</button>
 *   </div>
 */
export default class extends Controller {
  static targets = [
    "input",
    "pattern",
    "highlightArea",
    "explainer",
    "flagG",
    "flagI",
    "flagM",
    "flagS",
    "flagsDisplay",
    "matchCount",
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  connect() {
    // Flags state — "g" on by default
    this.flags = { g: true, i: false, m: false, s: false };
    this._syncFlagButtons();
    this._autosizePattern();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /**
   * evaluate — live matching + explanation, fired on every input event.
   */
  evaluate() {
    this._autosizePattern();

    const rawPattern = this.patternTarget.value;
    const text = this.inputTarget.value;

    // Always update the explainer
    this._explain(rawPattern);

    // Empty pattern — just show raw text, zero matches
    if (rawPattern === "" || text === "") {
      this.highlightAreaTarget.textContent = text;
      this._setMatchCount(0);
      return;
    }

    // Build regex
    const flagStr = this._getFlags();
    let regex;
    try {
      regex = new RegExp(rawPattern, flagStr);
    } catch (e) {
      this.highlightAreaTarget.textContent = text;
      this._setMatchCount(0);
      this._showExplainerError(e.message);
      return;
    }

    // Highlight matches
    const { html, count } = this._highlightMatches(text, regex);
    this.highlightAreaTarget.innerHTML = html;
    this._setMatchCount(count);
  }

  /**
   * clear — reset all fields to blank.
   */
  clear() {
    this.patternTarget.value = "";
    this.inputTarget.value = "";
    this.highlightAreaTarget.textContent = "";
    this._setMatchCount(0);
    this.explainerTarget.innerHTML = "";
    this._autosizePattern();
  }

  /**
   * toggleFlag — toggle a single regex flag on/off.
   */
  toggleFlag(event) {
    const flag = event.currentTarget.dataset.flag;
    if (flag && flag in this.flags) {
      this.flags[flag] = !this.flags[flag];
    }
    this._syncFlagButtons();
    this.evaluate();
  }

  // ── Private: Flags ─────────────────────────────────────────────────────────

  /**
   * Collect active flags into a string like "gi".
   */
  _getFlags() {
    return Object.entries(this.flags)
      .filter(([, active]) => active)
      .map(([flag]) => flag)
      .join("");
  }

  /**
   * Sync flag button visual state with internal flags object.
   */
  _syncFlagButtons() {
    const mapping = {
      g: this.hasFlagGTarget ? this.flagGTarget : null,
      i: this.hasFlagITarget ? this.flagITarget : null,
      m: this.hasFlagMTarget ? this.flagMTarget : null,
      s: this.hasFlagSTarget ? this.flagSTarget : null,
    };

    Object.entries(mapping).forEach(([flag, el]) => {
      if (!el) return;
      const isActive = this.flags[flag];
      el.classList.toggle("active", isActive);
      el.setAttribute("aria-pressed", isActive ? "true" : "false");
    });

    // The pattern box reads as a real literal: /pattern/gims
    if (this.hasFlagsDisplayTarget) {
      this.flagsDisplayTarget.textContent = `/${this._getFlags()}`;
    }
  }

  // Grow the one-row pattern textarea to fit its content, so long patterns
  // wrap into view instead of scrolling off-screen. +4 covers the 2px borders
  // (scrollHeight excludes them under border-box sizing).
  _autosizePattern() {
    const field = this.patternTarget;
    field.style.height = "auto";
    field.style.height = `${field.scrollHeight + 4}px`;
  }

  // ── Private: Highlighting ──────────────────────────────────────────────────

  /**
   * Highlight matches in text and return {html, count}.
   */
  _highlightMatches(text, regex) {
    regex.lastIndex = 0;

    const parts = [];
    let lastIndex = 0;
    let count = 0;
    let match;

    while ((match = regex.exec(text)) !== null) {
      // Guard against zero-length match infinite loops
      if (match.index === regex.lastIndex) {
        regex.lastIndex++;
        continue;
      }

      count++;

      // Text before this match
      if (match.index > lastIndex) {
        parts.push(this._escapeHTML(text.slice(lastIndex, match.index)));
      }

      // The match
      parts.push(
        `<mark class="regex-match">${this._escapeHTML(match[0])}</mark>`,
      );

      lastIndex = regex.lastIndex;

      // Without global flag, exec only returns the first match
      if (!regex.global) break;
    }

    // Remaining text
    if (lastIndex < text.length) {
      parts.push(this._escapeHTML(text.slice(lastIndex)));
    }

    const html = parts.length > 0 ? parts.join("") : this._escapeHTML(text);

    return { html, count };
  }

  // ── Private: Explainer ─────────────────────────────────────────────────────

  /**
   * Tokenize and explain the current pattern visually.
   */
  _explain(rawPattern) {
    if (!rawPattern || rawPattern.length === 0) {
      this.explainerTarget.innerHTML = "";
      return;
    }

    const tokens = this._tokenize(rawPattern);
    const html = tokens
      .map(
        (t) =>
          `<span class="inline-flex items-center gap-1.5 px-2 py-1 rounded text-xs font-mono border ${t.colorClass}" title="${this._escapeAttr(t.description)}">` +
          `<span class="font-bold">${this._escapeHTML(t.raw)}</span>` +
          `<span class="opacity-70 text-[10px]">${this._escapeHTML(t.label)}</span>` +
          `</span>`,
      )
      .join(" ");

    this.explainerTarget.innerHTML = `<div class="flex flex-wrap gap-2">${html}</div>`;
  }

  _showExplainerError(message) {
    this.explainerTarget.innerHTML = `<div class="text-xs font-mono text-dojo-red">⚠️ ${this._escapeHTML(message)}</div>`;
  }

  /**
   * Parse a regex pattern string into an array of descriptive tokens.
   * Each token: { raw, label, description, colorClass }
   */
  _tokenize(pattern) {
    const tokens = [];
    let i = 0;

    while (i < pattern.length) {
      const ch = pattern[i];

      // ── Escaped characters (\d, \w, \s, \b, etc.) ─────────────────────
      if (ch === "\\" && i + 1 < pattern.length) {
        const next = pattern[i + 1];
        const pair = ch + next;
        const meta = this._ESCAPE_MAP[next];

        if (meta) {
          tokens.push({
            raw: pair,
            label: meta.label,
            description: meta.description,
            colorClass: meta.colorClass,
          });
        } else {
          tokens.push({
            raw: pair,
            label: "escaped",
            description: `Escaped literal character '${next}'`,
            colorClass: "bg-gray-700/50 border-gray-600 text-gray-300",
          });
        }
        i += 2;
        continue;
      }

      // ── Character class [...]  or [^...] ───────────────────────────────
      if (ch === "[") {
        let end = pattern.indexOf("]", i + 1);
        if (end === -1) end = pattern.length;
        const raw = pattern.slice(i, end + 1);
        const isNegated = raw.length > 2 && raw[1] === "^";
        tokens.push({
          raw,
          label: isNegated ? "negated set" : "char set",
          description: isNegated
            ? `Matches any character NOT in ${raw}`
            : `Matches any single character in ${raw}`,
          colorClass: "bg-yellow-500/20 border-yellow-500/40 text-yellow-300",
        });
        i = end + 1;
        continue;
      }

      // ── Groups (...) ───────────────────────────────────────────────────
      if (ch === "(") {
        // Find matching close paren (naive, no nesting support needed for explainer)
        let depth = 1;
        let end = i + 1;
        while (end < pattern.length && depth > 0) {
          if (pattern[end] === "(" && pattern[end - 1] !== "\\") depth++;
          if (pattern[end] === ")" && pattern[end - 1] !== "\\") depth--;
          end++;
        }
        const raw = pattern.slice(i, end);
        const isNonCapturing = raw.startsWith("(?:");
        const isLookahead = raw.startsWith("(?=") || raw.startsWith("(?!");
        const isLookbehind = raw.startsWith("(?<=") || raw.startsWith("(?<!");

        let label = "group";
        let description = `Capturing group: ${raw}`;

        if (isNonCapturing) {
          label = "non-capture";
          description = `Non-capturing group: ${raw}`;
        } else if (isLookahead) {
          label = raw.startsWith("(?=") ? "lookahead" : "neg lookahead";
          description = `${label}: ${raw}`;
        } else if (isLookbehind) {
          label = raw.startsWith("(?<=") ? "lookbehind" : "neg lookbehind";
          description = `${label}: ${raw}`;
        }

        tokens.push({
          raw,
          label,
          description,
          colorClass: "bg-purple-500/20 border-purple-500/40 text-purple-300",
        });
        i = end;
        continue;
      }

      // ── Quantifiers ────────────────────────────────────────────────────
      if (ch === "{") {
        const match = pattern.slice(i).match(/^\{(\d+(?:,\d*)?)\}/);
        if (match) {
          const raw = match[0];
          tokens.push({
            raw,
            label: "quantifier",
            description: `Repeat ${match[1]} times`,
            colorClass: "bg-orange-500/20 border-orange-500/40 text-orange-300",
          });
          i += raw.length;
          continue;
        }
      }

      if (ch === "+" || ch === "*" || ch === "?") {
        const quantMap = {
          "+": {
            label: "1 or more",
            description: "Matches one or more of the preceding element",
          },
          "*": {
            label: "0 or more",
            description: "Matches zero or more of the preceding element",
          },
          "?": {
            label: "optional",
            description:
              "Matches zero or one of the preceding element (or makes quantifier lazy)",
          },
        };
        const info = quantMap[ch];
        tokens.push({
          raw: ch,
          label: info.label,
          description: info.description,
          colorClass: "bg-orange-500/20 border-orange-500/40 text-orange-300",
        });
        i++;
        continue;
      }

      // ── Anchors ────────────────────────────────────────────────────────
      if (ch === "^") {
        tokens.push({
          raw: "^",
          label: "start",
          description:
            "Matches the start of the string (or line in multiline mode)",
          colorClass: "bg-red-500/20 border-red-500/40 text-red-300",
        });
        i++;
        continue;
      }

      if (ch === "$") {
        tokens.push({
          raw: "$",
          label: "end",
          description:
            "Matches the end of the string (or line in multiline mode)",
          colorClass: "bg-red-500/20 border-red-500/40 text-red-300",
        });
        i++;
        continue;
      }

      // ── Alternation ────────────────────────────────────────────────────
      if (ch === "|") {
        tokens.push({
          raw: "|",
          label: "or",
          description: "Alternation — matches the expression on either side",
          colorClass: "bg-pink-500/20 border-pink-500/40 text-pink-300",
        });
        i++;
        continue;
      }

      // ── Dot wildcard ───────────────────────────────────────────────────
      if (ch === ".") {
        tokens.push({
          raw: ".",
          label: "any char",
          description: "Matches any character except newline",
          colorClass: "bg-cyan-500/20 border-cyan-500/40 text-cyan-300",
        });
        i++;
        continue;
      }

      // ── Literal character ──────────────────────────────────────────────
      // Collect consecutive literals into one token for cleaner display
      let literal = ch;
      i++;
      while (i < pattern.length && !"\\[](){}+*?^$.|".includes(pattern[i])) {
        literal += pattern[i];
        i++;
      }
      tokens.push({
        raw: literal,
        label: "literal",
        description: `Matches the literal text "${literal}"`,
        colorClass: "bg-slate-600/40 border-slate-500/50 text-slate-200",
      });
    }

    return tokens;
  }

  /** Map of known backslash escape sequences. */
  get _ESCAPE_MAP() {
    return {
      d: {
        label: "digit",
        description: "Matches any digit [0-9]",
        colorClass: "bg-teal-500/20 border-teal-500/40 text-teal-300",
      },
      D: {
        label: "non-digit",
        description: "Matches any non-digit [^0-9]",
        colorClass: "bg-teal-500/20 border-teal-500/40 text-teal-300",
      },
      w: {
        label: "word char",
        description: "Matches any word character [a-zA-Z0-9_]",
        colorClass: "bg-teal-500/20 border-teal-500/40 text-teal-300",
      },
      W: {
        label: "non-word",
        description: "Matches any non-word character",
        colorClass: "bg-teal-500/20 border-teal-500/40 text-teal-300",
      },
      s: {
        label: "whitespace",
        description: "Matches any whitespace character",
        colorClass: "bg-teal-500/20 border-teal-500/40 text-teal-300",
      },
      S: {
        label: "non-space",
        description: "Matches any non-whitespace character",
        colorClass: "bg-teal-500/20 border-teal-500/40 text-teal-300",
      },
      b: {
        label: "boundary",
        description: "Matches a word boundary",
        colorClass: "bg-red-500/20 border-red-500/40 text-red-300",
      },
      B: {
        label: "non-boundary",
        description: "Matches a non-word boundary",
        colorClass: "bg-red-500/20 border-red-500/40 text-red-300",
      },
      n: {
        label: "newline",
        description: "Matches a newline character",
        colorClass: "bg-gray-500/20 border-gray-500/40 text-gray-300",
      },
      t: {
        label: "tab",
        description: "Matches a tab character",
        colorClass: "bg-gray-500/20 border-gray-500/40 text-gray-300",
      },
      r: {
        label: "carriage return",
        description: "Matches a carriage return",
        colorClass: "bg-gray-500/20 border-gray-500/40 text-gray-300",
      },
    };
  }

  // ── Private: Match count ───────────────────────────────────────────────────

  _setMatchCount(n) {
    if (this.hasMatchCountTarget) {
      this.matchCountTarget.textContent = n === 1 ? "1 match" : `${n} matches`;
    }
  }

  // ── Private: Utilities ─────────────────────────────────────────────────────

  _escapeHTML(str) {
    const div = document.createElement("div");
    div.textContent = str;
    return div.innerHTML;
  }

  _escapeAttr(str) {
    return str
      .replace(/&/g, "&amp;")
      .replace(/"/g, "&quot;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  }
}
