import { Controller } from "@hotwired/stimulus";

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
    // Activate the first tab by default
    const firstTab = this.tabTargets[0];
    if (firstTab) {
      this._activate(firstTab.dataset.tab);
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
  }
}
