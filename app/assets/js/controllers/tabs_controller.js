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
    const onboarded = localStorage.getItem("regex_dojo_onboarded") === "true";
    if (!onboarded) {
      this._activate("onboarding");
    } else {
      const activeTab = localStorage.getItem("regex_dojo_active_tab") || "home";
      this._activate(activeTab);
    }
  }

  switch(event) {
    event.preventDefault();
    const tabName = event.currentTarget.dataset.tab;
    localStorage.setItem("regex_dojo_active_tab", tabName);
    this._activate(tabName);
  }

  completeOnboarding(event) {
    event.preventDefault();
    localStorage.setItem("regex_dojo_onboarded", "true");
    localStorage.setItem("regex_dojo_active_tab", "home");
    this._activate("home");
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
    const isOnboarding = tabName === "onboarding";
    const header = document.getElementById("global-header");
    if (header) {
      header.classList.toggle("hidden", isOnboarding);
    }
    const hud = document.getElementById("global-hud");
    if (hud) {
      hud.classList.toggle("hidden", isOnboarding);
    }

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
