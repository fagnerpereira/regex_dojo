import { Controller } from "@hotwired/stimulus";

// Survives reloads so learners come back to the tab they were working in —
// without this, every reload resets to the first tab (the regex dojo).
const TAB_STORAGE_KEY = "regex_dojo_active_tab";

/**
 * TabsController — switches between dojo / sandbox / blitz / codex panels.
 *
 * HTML contract:
 *   <div data-controller="tabs">
 *     <button data-tabs-target="tab" data-action="click->tabs#switch" data-tab="dojo">Dojo</button>
 *     ...
 *     <div data-tabs-target="panel" data-tab="dojo">...</div>
 *     ...
 *   </div>
 */
export default class extends Controller {
  static targets = ["tab", "panel"];

  connect() {
    // Restore the last active tab, falling back to the first
    const names = this.tabTargets.map((tab) => tab.dataset.tab);
    const saved = this._readStorage(TAB_STORAGE_KEY);
    const initial = saved && names.includes(saved) ? saved : names[0];

    if (initial) {
      this._activate(initial);
    }
  }

  switch(event) {
    event.preventDefault();
    const tabName = event.currentTarget.dataset.tab;
    this._activate(tabName);
  }

  // Called from codex cards to load a pattern into the sandbox
  loadInSandbox(event) {
    const pattern = event.currentTarget.dataset.pattern;
    if (pattern) {
      // Switch to the sandbox tab
      this._activate("sandbox");

      // Find the sandbox pattern input and set its value
      setTimeout(() => {
        const sandboxInput = document.querySelector(
          '[data-sandbox-target="pattern"]',
        );
        if (sandboxInput) {
          sandboxInput.value = pattern;
          sandboxInput.dispatchEvent(new Event("input", { bubbles: true }));
        }
      }, 100);
    }
  }

  _activate(tabName) {
    // Update tab button styling
    this.tabTargets.forEach((tab) => {
      const isActive = tab.dataset.tab === tabName;
      tab.classList.toggle("active", isActive);
    });

    // Show / hide panels
    this.panelTargets.forEach((panel) => {
      const isMatch = panel.dataset.tab === tabName;
      if (isMatch) {
        panel.classList.remove("panel-hidden");
      } else {
        panel.classList.add("panel-hidden");
      }
    });

    this._writeStorage(TAB_STORAGE_KEY, tabName);
  }

  // localStorage throws in private browsing; tab memory is a convenience
  // and must never break switching.
  _readStorage(key) {
    try {
      return localStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  _writeStorage(key, value) {
    try {
      localStorage.setItem(key, value);
    } catch (_) {
      // Storage unavailable — tabs still work, they just won't be remembered.
    }
  }
}
