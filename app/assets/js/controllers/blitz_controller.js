import { Controller } from "@hotwired/stimulus";

/**
 * BlitzController — timed quick-fire regex challenges.
 *
 * Katas data is loaded from a <script id="blitz-katas-data"> JSON tag
 * embedded in the Phlex BlitzPanel component.
 */
export default class extends Controller {
  static targets = [
    "startScreen",
    "gamePanel",
    "resultPanel",
    "timer",
    "timerBar",
    "score",
    "solvedCount",
    "concept",
    "kataTitle",
    "task",
    "xpBadge",
    "testString",
    "patternInput",
    "feedback",
    "finalScore",
    "finalSolved",
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  connect() {
    this.totalTime = 30;
    this.timeRemaining = 0;
    this.currentScore = 0;
    this.solvedCount = 0;
    this.currentKata = null;
    this.timerInterval = null;
    this.usedKataIds = new Set();
    this.katas = [];

    this._loadKatasFromPage();
  }

  disconnect() {
    this._stopTimer();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  start() {
    this.timeRemaining = this.totalTime;
    this.currentScore = 0;
    this.solvedCount = 0;
    this.usedKataIds.clear();

    // Update displays
    this._updateTimer();
    this._updateScoreDisplay();

    // Show game, hide start + results
    this.startScreenTarget.classList.add("panel-hidden");
    this.resultPanelTarget.classList.add("panel-hidden");
    this.gamePanelTarget.classList.remove("panel-hidden");

    // Load first kata
    this._nextKata();

    // Start countdown
    this._stopTimer();
    this.timerInterval = setInterval(() => this._tick(), 1000);
  }

  submit() {
    if (!this.currentKata || this.timeRemaining <= 0) return;

    const rawPattern = this.patternInputTarget.value.trim();
    if (rawPattern === "") return;

    let regex;
    try {
      regex = new RegExp(rawPattern);
    } catch (_) {
      this._showFeedback("❌ Invalid regex syntax", "text-dojo-red bg-dojo-red/10 border border-dojo-red/30");
      return;
    }

    const allPassed = this.currentKata.test_cases.every((tc) => {
      try {
        const matchData = tc.input.match(regex);
        const userMatch = matchData ? matchData[0] : null;
        return (userMatch === (tc.expected_match || null));
      } catch (_) {
        return false;
      }
    });

    if (allPassed) {
      const speedMultiplier = Math.max(this.timeRemaining / this.totalTime, 0.1);
      const baseXP = this.currentKata.xp || 25;
      const earned = Math.round(baseXP * (1 + speedMultiplier));

      this.currentScore += earned;
      this.solvedCount++;
      this._updateScoreDisplay();

      this._showFeedback(`✅ +${earned} XP!`, "text-dojo-green bg-dojo-green/10 border border-dojo-green/30");

      setTimeout(() => this._nextKata(), 500);
    } else {
      this._showFeedback("❌ Not all test cases pass — keep trying!", "text-dojo-red bg-dojo-red/10 border border-dojo-red/30");
    }
  }

  liveCheck() {
    // Optional: could add live highlighting during blitz
    // Left as no-op for speed
  }

  restart() {
    this.start();
  }

  // ── Private: Timer ─────────────────────────────────────────────────────────

  _tick() {
    this.timeRemaining--;
    this._updateTimer();

    if (this.timeRemaining <= 0) {
      this._end();
    }
  }

  _updateTimer() {
    if (this.hasTimerTarget) {
      this.timerTarget.textContent = this.timeRemaining;

      // Color coding + danger animation
      this.timerTarget.classList.remove("text-dojo-cyan", "text-dojo-gold", "danger");
      if (this.timeRemaining > 15) {
        this.timerTarget.classList.add("text-dojo-cyan");
      } else if (this.timeRemaining > 5) {
        this.timerTarget.classList.add("text-dojo-gold");
      } else {
        this.timerTarget.classList.add("danger");
      }
    }

    // Timer progress bar
    if (this.hasTimerBarTarget) {
      const pct = Math.max((this.timeRemaining / this.totalTime) * 100, 0);
      this.timerBarTarget.style.width = `${pct}%`;
    }
  }

  _stopTimer() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
      this.timerInterval = null;
    }
  }

  // ── Private: Kata management ───────────────────────────────────────────────

  _nextKata() {
    if (this.katas.length === 0) return;

    if (this.usedKataIds.size >= this.katas.length) {
      this.usedKataIds.clear();
    }

    const available = this.katas.filter((k) => !this.usedKataIds.has(k.id));
    const kata = available[Math.floor(Math.random() * available.length)];

    this.currentKata = kata;
    this.usedKataIds.add(kata.id);

    // Populate game panel
    if (this.hasConceptTarget) this.conceptTarget.textContent = kata.concept || "";
    if (this.hasKataTitleTarget) this.kataTitleTarget.textContent = kata.title;
    if (this.hasTaskTarget) this.taskTarget.innerHTML = kata.task || "";
    if (this.hasXpBadgeTarget) this.xpBadgeTarget.textContent = `+${kata.xp} XP`;
    if (this.hasTestStringTarget) this.testStringTarget.textContent = kata.test_string;
    if (this.hasPatternInputTarget) {
      this.patternInputTarget.value = "";
      this.patternInputTarget.focus();
    }
    this._hideFeedback();
  }

  _loadKatasFromPage() {
    const scriptTag = document.getElementById("blitz-katas-data");
    if (scriptTag) {
      try {
        this.katas = JSON.parse(scriptTag.textContent);
      } catch (_) {
        this.katas = [];
      }
    }
  }

  // ── Private: Scoring ───────────────────────────────────────────────────────

  _updateScoreDisplay() {
    if (this.hasScoreTarget) this.scoreTarget.textContent = this.currentScore;
    if (this.hasSolvedCountTarget) this.solvedCountTarget.textContent = this.solvedCount;
  }

  // ── Private: Game end ──────────────────────────────────────────────────────

  _end() {
    this._stopTimer();

    // Hide game, show results
    this.gamePanelTarget.classList.add("panel-hidden");
    this.resultPanelTarget.classList.remove("panel-hidden");

    // Update final scores
    if (this.hasFinalScoreTarget) this.finalScoreTarget.textContent = this.currentScore;
    if (this.hasFinalSolvedTarget) this.finalSolvedTarget.textContent = this.solvedCount;
  }

  // ── Private: Feedback ──────────────────────────────────────────────────────

  _showFeedback(message, classes) {
    if (!this.hasFeedbackTarget) return;
    this.feedbackTarget.textContent = message;
    this.feedbackTarget.className = `text-xs font-mono p-2 rounded ${classes}`;
    this.feedbackTarget.classList.remove("hidden");
  }

  _hideFeedback() {
    if (!this.hasFeedbackTarget) return;
    this.feedbackTarget.classList.add("hidden");
  }
}
