import { Controller } from "@hotwired/stimulus";
import { PatternField } from "../lib/pattern_field";
import { gradeTestCase } from "../lib/grading";
import { escapeHTML, markFirst } from "../lib/highlight";

// The Organic Blitz: 30 seconds, random non-hard challenges, grading on
// every keystroke with automatic advance once all tests pass, Pular to skip.
// The final score is persisted server-side (fire-and-forget POST); the
// record shown comes from the database. Registered as "blitz-page" while the
// legacy dashboard still owns the "blitz" name; the final swap renames it.
//
// innerHTML sinks receive escapeHTML-built strings, except the task line,
// which is trusted seed content carrying its own inline markup.
export default class extends Controller {
  static targets = [
    "startScreen",
    "runScreen",
    "endScreen",
    "time",
    "bar",
    "score",
    "task",
    "testsList",
    "field",
    "best",
    "result",
  ];

  static values = { challenges: Array, best: Number };

  connect() {
    this.running = false;
    this.patternField = new PatternField({
      textarea: this.fieldTarget,
      onChange: () => this.evaluate(),
    });
  }

  disconnect() {
    this.stopTimer();
    this.patternField?.destroy();
  }

  start() {
    this.running = true;
    this.timeLeft = 30;
    this.score = 0;
    this.current = null;
    this.scoreTarget.textContent = "0";
    this.timeTarget.textContent = "30";
    this.barTarget.style.width = "100%";

    this.startScreenTarget.classList.add("hidden");
    this.endScreenTarget.classList.add("hidden");
    this.runScreenTarget.classList.remove("hidden");

    this.nextChallenge();
    this.stopTimer();
    this.timer = setInterval(() => this.tick(), 1000);
  }

  tick() {
    this.timeLeft--;
    this.timeTarget.textContent = String(this.timeLeft);
    this.barTarget.style.width = `${Math.max(0, (this.timeLeft / 30) * 100)}%`;
    if (this.timeLeft <= 0) this.finish();
  }

  finish() {
    this.stopTimer();
    this.running = false;

    const best = Math.max(this.bestValue, this.score);
    this.bestValue = best;
    this.bestTarget.textContent = String(best);

    this.runScreenTarget.classList.add("hidden");
    this.resultTarget.textContent =
      `${this.score} ${this.score === 1 ? "desafio resolvido" : "desafios resolvidos"} · recorde ${best}`;
    this.endScreenTarget.classList.remove("hidden");

    this.persistScore();
  }

  // Fire-and-forget: a lost record simply re-establishes itself next run.
  persistScore() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content;

    fetch("/blitz/score", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(token ? { "X-CSRF-Token": token } : {}),
      },
      body: JSON.stringify({ score: this.score, speed_multiplier: 1.0 }),
    }).catch(() => {});
  }

  skip() {
    if (this.running) this.nextChallenge();
  }

  nextChallenge() {
    const pool = this.challengesValue;
    if (!pool.length) return;

    let next;
    do {
      next = pool[Math.floor(Math.random() * pool.length)];
    } while (pool.length > 1 && next === this.current);

    this.current = next;
    this.taskTarget.innerHTML = next.task;
    this.patternField.setValue("");
    this.evaluate();
    this.patternField.focus();
  }

  evaluate() {
    if (!this.current) return;

    const pattern = this.patternField.pattern;
    let regex = null;
    try {
      if (pattern) regex = new RegExp(pattern);
    } catch (_) {
      regex = null;
    }

    let passCount = 0;
    this.testsListTarget.innerHTML = this.current.test_cases
      .map((testCase) => {
        const ok = Boolean(pattern) && gradeTestCase(pattern, "", testCase);
        if (ok) passCount++;

        const match = regex ? testCase.input.match(regex) : null;
        const shown = markFirst(testCase.input, match);
        const expectation =
          testCase.expected_match != null ? `“${escapeHTML(testCase.expected_match)}”` : "nada";
        const status = ok
          ? '<span class="w-2.5 h-2.5 shrink-0 rounded-full bg-sage-500"></span>'
          : '<span class="w-2.5 h-2.5 shrink-0 rounded-full border border-ink/25"></span>';

        return (
          '<div class="flex items-center gap-3 rounded-xl bg-dune-100 px-4 py-2">' +
          `<span class="font-mono text-[13.5px] flex-1">${shown}</span>` +
          `<span class="text-[11px] text-ink/45">${expectation}</span>` +
          status +
          "</div>"
        );
      })
      .join("");

    if (this.running && pattern && passCount === this.current.test_cases.length) {
      this.score++;
      this.scoreTarget.textContent = String(this.score);
      this.nextChallenge();
    }
  }

  stopTimer() {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
  }
}
