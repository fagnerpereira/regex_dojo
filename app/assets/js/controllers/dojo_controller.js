import { Controller } from "@hotwired/stimulus";
import { post } from "@rails/request.js";

/**
 * DojoController — the main kata challenge mode.
 *
 * Kata data is embedded on sidebar buttons via data attributes:
 *   data-kata-id, data-kata-title, data-kata-concept, data-kata-lesson,
 *   data-kata-test-string, data-kata-task, data-kata-hint, data-kata-xp,
 *   data-kata-test-cases (JSON)
 */
export default class extends Controller {
  static targets = [
    "kataButton",
    "concept",
    "title",
    "lesson",
    "task",
    "xpBadge",
    "highlightArea",
    "patternInput",
    "errorBanner",
    "testCasesList",
    "hintText",
    "formContainer",
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  connect() {
    this.currentKata = null;
    this.testCases = [];
    this.hintVisible = false;

    // Auto-select the first kata on page load
    if (this.kataButtonTargets.length > 0) {
      this._loadKataFromButton(this.kataButtonTargets[0]);
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /**
   * selectKata — fired when user clicks a sidebar kata button.
   * Reads all kata data from the button's data attributes and populates the
   * right-side arena panel.
   */
  selectKata(event) {
    const button = event.currentTarget;
    this._loadKataFromButton(button);
  }

  /**
   * evaluatePattern — triggered on every keystroke in the pattern input.
   * Creates a RegExp from the user's input, highlights matches in the test
   * string with <mark> tags, and checks each test case for pass/fail.
   */
  evaluatePattern() {
    const rawPattern = this.patternInputTarget.value.trim();

    // Clear everything when input is empty
    if (rawPattern === "") {
      this._clearHighlights();
      this._clearError();
      this._resetTestCaseStatus();
      return;
    }

    // Attempt to build regex — show error banner on invalid patterns
    let regex;
    try {
      regex = new RegExp(rawPattern, "g");
      this._clearError();
    } catch (e) {
      this._showError(e.message);
      this._clearHighlights();
      this._resetTestCaseStatus();
      return;
    }

    // Highlight matches in the test string
    if (this.currentKata) {
      const highlighted = this._highlightMatches(
        this.currentKata.testString,
        regex,
      );
      this.highlightAreaTarget.innerHTML = highlighted;
    }

    // Validate each test case
    this._checkTestCases(rawPattern);
  }

  /**
   * revealHint — toggle the hint box visibility.
   */
  revealHint() {
    this.hintVisible = !this.hintVisible;
    this.hintTextTarget.classList.toggle("hidden", !this.hintVisible);
  }

  /**
   * submit — validate all test cases pass, then POST to /kata/{id}/check.
   * On success: animate success, show XP gain, update HUD.
   * On failure: shake the card with error animation.
   */
  async submit() {
    if (!this.currentKata) return;

    const rawPattern = this.patternInputTarget.value.trim();

    if (rawPattern === "") {
      this._showError("Pattern cannot be empty.");
      return;
    }

    // Client-side pre-check: verify all test cases pass
    let regex;
    try {
      regex = new RegExp(rawPattern, "g");
    } catch (e) {
      this._showError(e.message);
      return;
    }

    const allPassed = this._allTestCasesPass(rawPattern);

    if (!allPassed) {
      this._shakeCard("shake-error");
      this._showError(
        "Not all test cases pass yet. Keep tweaking your pattern!",
      );
      return;
    }

    // POST to backend
    try {
      const response = await post(`/kata/${this.currentKata.id}/check`, {
        body: JSON.stringify({ pattern: rawPattern }),
        contentType: "application/json",
        responseKind: "json",
      });

      if (response.ok) {
        const data = await response.json;
        this._onSuccess(data);
      } else {
        // Server rejected the pattern (edge cases the client might miss)
        let errorMsg = "Pattern rejected by server.";
        try {
          const data = await response.json;
          if (data && data.error) errorMsg = data.error;
        } catch (_) {
          // ignore parse error
        }
        this._shakeCard("shake-error");
        this._showError(errorMsg);
      }
    } catch (networkError) {
      this._shakeCard("shake-error");
      this._showError("Network error — please try again.");
    }
  }

  // ── Private: Kata loading ──────────────────────────────────────────────────

  _loadKataFromButton(button) {
    const ds = button.dataset;

    this.currentKata = {
      id: ds.kataId,
      title: ds.kataTitle,
      concept: ds.kataConcept,
      lesson: ds.kataLesson,
      testString: ds.kataTestString,
      task: ds.kataTask,
      hint: ds.kataHint,
      xp: parseInt(ds.kataXp, 10),
    };

    // Parse JSON test cases
    try {
      this.testCases = JSON.parse(ds.kataTestCases);
    } catch (_) {
      this.testCases = [];
    }

    // Reset UI state
    this.hintVisible = false;
    this.patternInputTarget.value = "";
    this._clearError();

    // Populate the right panel
    this.conceptTarget.textContent = this.currentKata.concept;
    this.titleTarget.textContent = this.currentKata.title;
    this.lessonTarget.innerHTML = this.currentKata.lesson;
    this.taskTarget.innerHTML = this.currentKata.task;
    this.xpBadgeTarget.textContent = `+${this.currentKata.xp} XP`;
    this.highlightAreaTarget.textContent = this.currentKata.testString;

    // Hint
    this.hintTextTarget.textContent = this.currentKata.hint;
    this.hintTextTarget.classList.add("hidden");

    // Render test case cards
    this._renderTestCases(this.testCases);

    // Highlight active sidebar button
    this.kataButtonTargets.forEach((btn) => {
      const isActive = btn.dataset.kataId === this.currentKata.id;
      btn.classList.toggle("bg-dojo-bg", isActive);
      btn.classList.toggle("border-dojo-border", isActive);
      btn.classList.toggle("border-transparent", !isActive);
    });
  }

  // ── Private: Test cases ────────────────────────────────────────────────────

  /**
   * Render test case cards in the test cases grid.
   * Each card shows the input text and expected match/no-match result.
   */
  _renderTestCases(testCases) {
    const container = this.testCasesListTarget;
    container.innerHTML = "";

    testCases.forEach((tc, index) => {
      const card = document.createElement("div");
      card.className =
        "test-case-card flex items-center gap-3 bg-dojo-bg/60 border border-dojo-border/60 p-3 rounded-lg transition-all duration-200";
      card.dataset.testCaseIndex = index;

      const statusIcon = document.createElement("span");
      statusIcon.className = "test-case-icon text-lg flex-shrink-0";
      statusIcon.textContent = "⬜";

      const details = document.createElement("div");
      details.className = "flex flex-col flex-1 min-w-0";

      const input = document.createElement("span");
      input.className = "text-xs font-mono text-gray-300 truncate";
      input.textContent = `"${tc.input}"`;

      const expected = document.createElement("span");
      expected.className = "text-[10px] font-mono text-gray-500 mt-0.5";
      expected.textContent = tc.should_match
        ? `→ expected: "${tc.expected_match || ""}"`
        : "→ expected: no match";

      details.appendChild(input);
      details.appendChild(expected);

      card.appendChild(statusIcon);
      card.appendChild(details);
      container.appendChild(card);
    });
  }

  /**
   * Check each test case against the current pattern and update card status
   * with pass (✅) / fail (❌) indicators.
   */
  _checkTestCases(rawPattern) {
    const cards = this.testCasesListTarget.querySelectorAll(".test-case-card");

    this.testCases.forEach((tc, index) => {
      const card = cards[index];
      if (!card) return;

      const icon = card.querySelector(".test-case-icon");
      const details = card.querySelector("div");

      // Remove any existing user-match span
      const oldUserMatch = details.querySelector(".user-match-result");
      if (oldUserMatch) oldUserMatch.remove();

      let userMatch = null;
      let passed = false;
      try {
        const re = new RegExp(rawPattern);
        const matchData = tc.input.match(re);
        userMatch = matchData ? matchData[0] : null;
        passed = (userMatch === (tc.expected_match || null));
      } catch (_) {
        passed = false;
      }

      icon.textContent = passed ? "✅" : "❌";
      card.classList.toggle("border-green-500/30", passed);
      card.classList.toggle("border-red-500/30", !passed);
      card.classList.toggle("border-dojo-border/60", false);

      const userMatchSpan = document.createElement("span");
      userMatchSpan.className = `user-match-result text-[10px] font-mono mt-0.5 ${
        passed ? "text-dojo-green" : "text-dojo-red font-bold"
      }`;
      userMatchSpan.textContent = userMatch !== null
        ? `got: "${userMatch}"`
        : "got: no match";
      details.appendChild(userMatchSpan);
    });
  }

  /**
   * Returns true if all test cases pass for the given pattern.
   */
  _allTestCasesPass(rawPattern) {
    return this.testCases.every((tc) => {
      try {
        const re = new RegExp(rawPattern);
        const matchData = tc.input.match(re);
        const userMatch = matchData ? matchData[0] : null;
        return (userMatch === (tc.expected_match || null));
      } catch (_) {
        return false;
      }
    });
  }

  /**
   * Reset all test case card icons back to neutral.
   */
  _resetTestCaseStatus() {
    const cards = this.testCasesListTarget.querySelectorAll(".test-case-card");
    cards.forEach((card) => {
      const icon = card.querySelector(".test-case-icon");
      if (icon) icon.textContent = "⬜";
      const details = card.querySelector("div");
      const oldUserMatch = details.querySelector(".user-match-result");
      if (oldUserMatch) oldUserMatch.remove();
      card.classList.remove("border-green-500/30", "border-red-500/30");
      card.classList.add("border-dojo-border/60");
    });
  }

  // ── Private: Highlighting ──────────────────────────────────────────────────

  /**
   * Return an HTML string with regex matches wrapped in <mark> tags.
   */
  _highlightMatches(text, regex) {
    // Reset lastIndex in case the regex is stateful (global flag)
    regex.lastIndex = 0;

    const parts = [];
    let lastIndex = 0;
    let match;

    while ((match = regex.exec(text)) !== null) {
      // Guard against zero-length matches causing infinite loops
      if (match.index === regex.lastIndex) {
        regex.lastIndex++;
        continue;
      }

      // Text before the match
      if (match.index > lastIndex) {
        parts.push(this._escapeHTML(text.slice(lastIndex, match.index)));
      }

      // The match itself
      parts.push(
        `<mark class="regex-match">${this._escapeHTML(match[0])}</mark>`,
      );

      lastIndex = regex.lastIndex;
    }

    // Remaining text after last match
    if (lastIndex < text.length) {
      parts.push(this._escapeHTML(text.slice(lastIndex)));
    }

    return parts.length > 0 ? parts.join("") : this._escapeHTML(text);
  }

  _clearHighlights() {
    if (this.currentKata) {
      this.highlightAreaTarget.textContent = this.currentKata.testString;
    }
  }

  // ── Private: Error banner ──────────────────────────────────────────────────

  _showError(message) {
    this.errorBannerTarget.textContent = `⚠️ ${message}`;
    this.errorBannerTarget.classList.remove("hidden");
  }

  _clearError() {
    this.errorBannerTarget.textContent = "";
    this.errorBannerTarget.classList.add("hidden");
  }

  // ── Private: Success / failure animations ──────────────────────────────────

  _onSuccess(data) {
    // Clear error state
    this._clearError();

    // Show success banner
    const xpGained = data?.xp_awarded ?? this.currentKata.xp;
    this._showSuccessBanner(xpGained);

    // Shake-success animation on the card
    this._shakeCard("shake-success");

    // Update HUD XP display
    this._updateHudXP(xpGained);

    // Update HUD belt badge dynamically
    const beltBadge = document.getElementById("hud-belt-badge");
    if (beltBadge && data.belt) {
      const newBeltText = `${data.belt.charAt(0).toUpperCase() + data.belt.slice(1)} Belt`;
      if (beltBadge.textContent.trim() !== newBeltText) {
        beltBadge.textContent = newBeltText;

        const beltStyles = {
          white: ["text-white", "border-white/20", "bg-white/5", "shadow-white/5"],
          yellow: ["text-dojo-gold", "border-dojo-gold/20", "bg-dojo-gold/5", "shadow-dojo-gold/5"],
          orange: ["text-orange-400", "border-orange-400/20", "bg-orange-400/5", "shadow-orange-400/5"],
          green: ["text-dojo-green", "border-dojo-green/20", "bg-dojo-green/5", "shadow-dojo-green/5"],
          black: ["text-purple-400", "border-purple-400/20", "bg-purple-400/5", "shadow-purple-400/5"]
        };

        // Reset any existing belt classes
        Object.values(beltStyles).flat().forEach(cls => beltBadge.classList.remove(cls));

        // Add corresponding style classes
        const newClasses = beltStyles[data.belt.toLowerCase()] || ["text-dojo-cyan", "border-dojo-border", "bg-dojo-bg"];
        beltBadge.classList.add(...newClasses);

        // Play level up celebration bounce
        beltBadge.classList.add("animate-bounce");
        setTimeout(() => {
          beltBadge.classList.remove("animate-bounce");
        }, 2500);
      }
    }

    // Mark the sidebar button as completed
    this._markKataComplete(this.currentKata.id);

    // Auto-advance to the next kata after a short delay
    setTimeout(() => {
      this._advanceToNextKata();
    }, 2000);
  }

  _showSuccessBanner(xp) {
    // Create a temporary banner overlaying the form area
    const banner = document.createElement("div");
    banner.className =
      "fixed top-24 left-1/2 -translate-x-1/2 z-50 bg-green-500/90 text-white font-bold text-lg px-8 py-4 rounded-xl shadow-2xl flex items-center gap-3 animate-bounce";
    banner.innerHTML = `<span class="text-2xl">✅</span> Kata Solved! <span class="text-dojo-gold font-mono">+${xp} XP</span>`;
    document.body.appendChild(banner);

    // Remove banner after 2.5 seconds
    setTimeout(() => {
      banner.remove();
    }, 2500);
  }

  _shakeCard(animationClass) {
    const card = this.element.querySelector(".kata-card");
    if (!card) return;

    card.classList.add(animationClass);
    card.addEventListener(
      "animationend",
      () => {
        card.classList.remove(animationClass);
      },
      { once: true },
    );
  }

  _updateHudXP(xpGained) {
    // Find the HUD XP display (outside this controller's scope)
    const hudBar = document.getElementById("hud-bar");
    if (!hudBar) return;

    // Find the XP label (format: "120/200 XP")
    const xpLabel = hudBar.querySelector(".text-dojo-gold");
    if (!xpLabel) return;

    const match = xpLabel.textContent.match(/(\d+)\/(\d+)\s*XP/);
    if (match) {
      const currentXP = parseInt(match[1], 10) + xpGained;
      const maxXP = parseInt(match[2], 10);
      xpLabel.textContent = `${currentXP}/${maxXP} XP`;

      // Update progress bar width
      const progressBar = hudBar.querySelector(".belt-bar");
      if (progressBar) {
        const percentage = Math.min(
          Math.round((currentXP / maxXP) * 100),
          100,
        );
        progressBar.style.width = `${percentage}%`;
      }
    }
  }

  _markKataComplete(kataId) {
    const button = this.kataButtonTargets.find(
      (btn) => btn.dataset.kataId === kataId,
    );
    if (button) {
      // Add a visual completion indicator
      if (!button.querySelector(".kata-complete-badge")) {
        const badge = document.createElement("span");
        badge.className = "kata-complete-badge text-green-400 text-sm ml-2";
        badge.textContent = "✓";
        button.appendChild(badge);
      }
    }
  }

  _advanceToNextKata() {
    const currentIndex = this.kataButtonTargets.findIndex(
      (btn) => btn.dataset.kataId === this.currentKata.id,
    );
    const nextIndex = currentIndex + 1;

    if (nextIndex < this.kataButtonTargets.length) {
      this._loadKataFromButton(this.kataButtonTargets[nextIndex]);
    }
  }

  // ── Private: Utilities ─────────────────────────────────────────────────────

  _escapeHTML(str) {
    const div = document.createElement("div");
    div.textContent = str;
    return div.innerHTML;
  }
}
