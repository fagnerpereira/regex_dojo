import { Controller } from "@hotwired/stimulus";
import { post } from "@rails/request.js";

// The ruby track's controller. Deliberately the inverse of dojo_controller:
// there is no in-browser Ruby grader, so every submit POSTs and the server's
// verdict (structural match, or sandboxed execution of the answer) is the
// only authority. No per-keystroke feedback — recall practice works better
// when the answer isn't converged upon by hints.
//
// After EVERY graded answer — right or wrong — the kata's approaches
// (code + why) render below the form, and the learner stays on this
// challenge: no reload, no tab reset, no auto-advance.
export default class extends Controller {
  static targets = [
    "input",
    "errorBanner",
    "successBanner",
    "hintText",
    "suggestions",
    "solvedCounter",
  ];
  static values = { challengeId: Number };

  connect() {
    this.inputTarget.focus();

    // ruby_after/ruby_before are one-shot cursors from the next/previous
    // links. Scrub them so a reload, bookmark or session restore lands on
    // first-unsolved selection instead of being pinned here forever.
    const params = new URLSearchParams(window.location.search);
    if (params.has("ruby_after") || params.has("ruby_before")) {
      window.history.replaceState(null, "", window.location.pathname);
    }
  }

  async submit() {
    const answer = this.inputTarget.value.trim();
    this._hideBanners();

    try {
      const response = await post(`/kata/${this.challengeIdValue}/check`, {
        body: JSON.stringify({ pattern: answer }),
        contentType: "application/json",
        responseKind: "json",
      });

      const data = await response.json;

      if (response.ok && data.passing) {
        this._onSuccess(data);
      } else {
        this._showError(
          data.feedback ||
            data.error_message ||
            "Not quite — compare your result with the expected output and try again.",
        );
      }

      this._renderSuggestions(data.suggestions);
    } catch {
      this._showError("Network error — please try again.");
    }
  }

  revealHint() {
    this.hintTextTarget.classList.remove("hidden");
  }

  _onSuccess(data) {
    const xp = data.xp_awarded ?? 0;
    const xpNote = xp > 0 ? `+${xp} XP` : "already solved — no XP";

    this.successBannerTarget.textContent = data.idiomatic
      ? `✅ Correct! ${xpNote}`
      : `✅ Correct — your code returns the right result! ${xpNote}. The idiomatic forms below are worth learning:`;
    this.successBannerTarget.classList.remove("hidden");

    if (xp > 0) {
      this._bumpSolvedCounter();
      this._updateHudXP(data.total_xp);
    }
  }

  _showError(message) {
    this.errorBannerTarget.textContent = message;
    this.errorBannerTarget.classList.remove("hidden");
  }

  _hideBanners() {
    this.errorBannerTarget.classList.add("hidden");
    this.successBannerTarget.classList.add("hidden");
  }

  // Render the kata's approaches with safe DOM construction — the notes and
  // code come from challenge content, never interpolated as HTML.
  _renderSuggestions(suggestions) {
    if (!this.hasSuggestionsTarget || !suggestions?.length) return;

    const container = this.suggestionsTarget;
    container.textContent = "";

    const heading = document.createElement("span");
    heading.className =
      "text-xs font-mono text-dojo-purple font-bold uppercase";
    heading.textContent = "💡 Ways to solve this:";
    container.appendChild(heading);

    suggestions.forEach(({ code, note }) => {
      const item = document.createElement("div");
      item.className = "flex flex-col gap-1 mt-2";

      const codeEl = document.createElement("code");
      codeEl.className =
        "font-mono text-sm text-dojo-cyan bg-dojo-bg border border-dojo-border px-3 py-2 rounded";
      codeEl.textContent = code;
      item.appendChild(codeEl);

      if (note) {
        const noteEl = document.createElement("p");
        noteEl.className = "text-xs text-gray-400 leading-relaxed";
        noteEl.textContent = note;
        item.appendChild(noteEl);
      }

      container.appendChild(item);
    });

    container.classList.remove("hidden");
    container.classList.add("flex");
  }

  _bumpSolvedCounter() {
    if (!this.hasSolvedCounterTarget) return;

    const match = this.solvedCounterTarget.textContent.match(/(\d+)\/(\d+)/);
    if (match) {
      const solved = Math.min(
        parseInt(match[1], 10) + 1,
        parseInt(match[2], 10),
      );
      this.solvedCounterTarget.textContent = `${solved}/${match[2]} solved`;
    }
  }

  // Mirrors dojo_controller's HUD update: the server's total is authoritative.
  _updateHudXP(totalXP) {
    if (typeof totalXP !== "number") return;

    const hudBar = document.getElementById("hud-bar");
    if (!hudBar) return;

    const xpLabel = hudBar.querySelector(".text-dojo-gold");
    if (!xpLabel) return;

    const match = xpLabel.textContent.match(/(\d+)\/(\d+)\s*XP/);
    if (match) {
      const maxXP = parseInt(match[2], 10);
      xpLabel.textContent = `${totalXP}/${maxXP} XP`;

      const progressBar = hudBar.querySelector(".belt-bar");
      if (progressBar) {
        const percentage = Math.min(Math.round((totalXP / maxXP) * 100), 100);
        progressBar.style.width = `${percentage}%`;
      }
    }
  }
}
