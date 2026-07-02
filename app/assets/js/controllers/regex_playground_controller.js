// app/javascript/controllers/regex_playground_controller.js
//
// Mirrors the logic from the design reference's live playground.
// All matching runs client-side — no Turbo/server round trip needed.
//
// Expected targets (see phlex/screens/playground.rb data-* attrs):
//   pattern, flagsLabel, flags (container w/ [data-flag] pills), error,
//   testString, preview, matchBadge, matchList, successBanner

import { Controller } from "@hotwired/stimulus";

const DEFAULT_PATTERN = "#([a-f0-9]{6}|[a-f0-9]{3})\\b";
const DEFAULT_FLAGS = "gi";
const DEFAULT_TEST =
  "bg: #fff; color: #1c1830;\nborder: #7c3aed; shadow: #ggg999;\naccent: #f59e0b; text: #211b3a";

export default class extends Controller {
  static targets = [
    "pattern",
    "flagsLabel",
    "flags",
    "error",
    "testString",
    "preview",
    "matchBadge",
    "matchList",
    "successBanner",
  ];

  connect() {
    this.currentFlags = DEFAULT_FLAGS;
    this.run();
  }

  reset() {
    this.patternTarget.value = DEFAULT_PATTERN;
    this.testStringTarget.value = DEFAULT_TEST;
    this.currentFlags = DEFAULT_FLAGS;
    this.run();
  }

  toggleFlag(event) {
    const flag = event.currentTarget.dataset.flag;
    this.currentFlags = this.currentFlags.includes(flag)
      ? this.currentFlags.replace(flag, "")
      : this.currentFlags + flag;
    // keep canonical order g,i,m
    this.currentFlags = ["g", "i", "m"]
      .filter((f) => this.currentFlags.includes(f))
      .join("");
    this.run();
  }

  run() {
    const pattern = this.patternTarget.value;
    const testString = this.testStringTarget.value;
    const flags = this.currentFlags;

    this.flagsLabelTarget.textContent = flags;
    this.flagsTarget.querySelectorAll("[data-flag]").forEach((pill) => {
      const active = flags.includes(pill.dataset.flag);
      pill.classList.toggle("bg-dojo-violet", active);
      pill.classList.toggle("text-white", active);
      pill.classList.toggle("bg-dojo-violet-light", !active);
      pill.classList.toggle("text-dojo-violet-dark", !active);
    });

    let matches = [];
    let error = null;

    if (pattern) {
      try {
        const re = new RegExp(
          pattern,
          flags.includes("g") ? flags : flags + "g",
        );
        let m;
        let guard = 0;
        while ((m = re.exec(testString)) !== null && guard < 500) {
          matches.push({
            text: m[0],
            start: m.index,
            end: m.index + m[0].length,
          });
          if (m[0].length === 0) re.lastIndex++;
          guard++;
        }
      } catch (e) {
        error = e.message;
      }
    }

    this.renderError(error);
    this.renderPreview(testString, matches, error);
    this.renderMatchList(matches, error);
  }

  renderError(error) {
    this.errorTarget.textContent = error ? `⚠ ${error}` : "";
    this.errorTarget.classList.toggle("hidden", !error);
  }

  renderPreview(testString, matches, error) {
    this.previewTarget.innerHTML = "";
    if (error || matches.length === 0) {
      this.previewTarget.append(document.createTextNode(testString));
      return;
    }
    let cursor = 0;
    for (const m of matches) {
      if (m.start > cursor) {
        this.previewTarget.append(
          document.createTextNode(testString.slice(cursor, m.start)),
        );
      }
      const mark = document.createElement("mark");
      mark.className =
        "bg-amber-200 text-amber-900 rounded px-0.5 font-semibold";
      mark.textContent = m.text;
      this.previewTarget.append(mark);
      cursor = m.end;
    }
    if (cursor < testString.length) {
      this.previewTarget.append(
        document.createTextNode(testString.slice(cursor)),
      );
    }
  }

  renderMatchList(matches, error) {
    const badge = this.matchBadgeTarget;
    badge.textContent = error ? "—" : `${matches.length} found`;
    badge.className = `inline-flex items-center rounded-full px-2.5 py-1 text-[11.5px] font-bold ${
      error
        ? "bg-dojo-danger-bg text-dojo-danger-text"
        : matches.length
          ? "bg-dojo-success-bg text-dojo-success-text"
          : "bg-dojo-violet-light text-slate-400"
    }`;

    this.matchListTarget.innerHTML = "";
    if (!error && matches.length === 0) {
      const empty = document.createElement("div");
      empty.className = "p-4 text-center text-[12.5px] text-slate-400";
      empty.textContent = "No matches yet — try a pattern above.";
      this.matchListTarget.append(empty);
    } else {
      for (const m of matches) {
        const row = document.createElement("div");
        row.className =
          "bg-white border border-dojo-violet-border rounded-xl px-3.5 py-3 flex justify-between";
        row.innerHTML = `<span class="font-mono text-sm font-semibold">${m.text}</span><span class="font-mono text-[11px] text-slate-400">${m.start}:${m.end}</span>`;
        this.matchListTarget.append(row);
      }
    }

    this.successBannerTarget.classList.toggle(
      "hidden",
      error || matches.length === 0,
    );
    this.successBannerTarget.textContent = `✓ ${matches.length} found — pattern is valid`;
  }
}
