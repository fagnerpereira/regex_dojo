import { Controller } from "@hotwired/stimulus";

// Reveals hidden elements on demand (Dica boxes and similar).
export default class extends Controller {
  static targets = ["item"];

  show() {
    this.itemTargets.forEach((element) => element.classList.remove("hidden"));
  }
}
