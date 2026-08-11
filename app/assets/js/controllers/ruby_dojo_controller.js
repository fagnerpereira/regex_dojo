import { Controller } from "@hotwired/stimulus";
import { post } from "@rails/request.js";

// The ruby track's controller. Deliberately the inverse of dojo_controller:
// there is no in-browser Ruby grader, so every submit POSTs and the server's
// Prism-based verdict is the only authority. No per-keystroke feedback —
// recall practice works better when the answer isn't converged upon by hints.
export default class extends Controller {
  static targets = ["input", "errorBanner", "successBanner", "hintText"];
  static values = { challengeId: Number };

  connect() {
    this.inputTarget.focus();
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
          data.error_message || "Not quite — compare your result with the expected output and try again.",
        );
      }
    } catch {
      this._showError("Network error — please try again.");
    }
  }

  revealHint() {
    this.hintTextTarget.classList.remove("hidden");
  }

  _onSuccess(data) {
    const xp = data.xp_awarded ?? 0;
    this.successBannerTarget.textContent =
      xp > 0 ? `✅ Correct! +${xp} XP` : "✅ Correct! (already solved — no XP)";
    this.successBannerTarget.classList.remove("hidden");

    // The server picks the next challenge; a reload renders it.
    setTimeout(() => window.location.reload(), 1500);
  }

  _showError(message) {
    this.errorBannerTarget.textContent = message;
    this.errorBannerTarget.classList.remove("hidden");
  }

  _hideBanners() {
    this.errorBannerTarget.classList.add("hidden");
    this.successBannerTarget.classList.add("hidden");
  }
}
