import { Controller } from "@hotwired/stimulus";

// Dark mode. The server reads the `theme` cookie and stamps html[data-dark]
// before the first paint, so this controller only owns the toggle itself and
// keeps Turbo-restored pages honest: a snapshot cached under one theme could
// be restored after the user toggled, so every Turbo render re-stamps the
// attribute from the cookie (the single source of truth).
export default class extends Controller {
  static targets = ["moonIcon", "sunIcon"];

  connect() {
    this.sync = () => {
      this.#stamp(this.#cookieTheme() === "dark");
      this.#swapIcons();
    };
    document.addEventListener("turbo:render", this.sync);
  }

  disconnect() {
    document.removeEventListener("turbo:render", this.sync);
  }

  toggle() {
    const next = this.#dark() ? "light" : "dark";
    document.cookie = `theme=${next}; path=/; max-age=31536000; samesite=lax`;
    this.#stamp(next === "dark");
    this.#swapIcons();
  }

  #dark() {
    return document.documentElement.hasAttribute("data-dark");
  }

  #cookieTheme() {
    const match = document.cookie.match(/(?:^|;\s*)theme=(\w+)/);
    return match ? match[1] : null;
  }

  #stamp(dark) {
    document.documentElement.toggleAttribute("data-dark", dark);
  }

  #swapIcons() {
    if (!this.hasMoonIconTarget || !this.hasSunIconTarget) return;

    this.moonIconTarget.classList.toggle("hidden", this.#dark());
    this.sunIconTarget.classList.toggle("hidden", !this.#dark());
  }
}
