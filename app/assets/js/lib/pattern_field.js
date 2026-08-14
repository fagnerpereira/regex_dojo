// The shared pattern field (Desafio, Sandbox, Blitz): an auto-growing
// one-row textarea with a syntax-highlight overlay, external flag buttons,
// and Enter-submits-instead-of-newline. Plain ES class — each Stimulus
// controller instantiates it in connect() and destroys it in disconnect().

import { highlightHTML } from "./tokenizer";

export class PatternField {
  constructor({ textarea, highlight = null, flagButtons = [], flagsText = null, onChange = null, onSubmit = null }) {
    this.textarea = textarea;
    this.highlight = highlight;
    this.flagButtons = Array.from(flagButtons);
    this.flagsText = flagsText;
    this.onChange = onChange;
    this.onSubmit = onSubmit;
    this.flags = new Set();

    this.handleInput = () => {
      this.fit();
      this.render();
      this.onChange?.();
    };

    // Enter never inserts a newline; it submits (when a handler is given).
    this.handleKeydown = (event) => {
      if (event.key !== "Enter") return;
      event.preventDefault();
      this.onSubmit?.();
    };

    this.textarea.addEventListener("input", this.handleInput);
    this.textarea.addEventListener("keydown", this.handleKeydown);

    this.flagHandlers = new Map();
    this.flagButtons.forEach((button) => {
      const handler = () => this.toggleFlag(button);
      this.flagHandlers.set(button, handler);
      button.addEventListener("click", handler);
    });

    this.fit();
    this.render();
  }

  get pattern() {
    return this.textarea.value;
  }

  get flagString() {
    return [...this.flags].join("");
  }

  setValue(value) {
    this.textarea.value = value;
    this.fit();
    this.render();
  }

  toggleFlag(button) {
    const flag = button.dataset.flag;
    if (this.flags.has(flag)) {
      this.flags.delete(flag);
      button.removeAttribute("data-on");
    } else {
      this.flags.add(flag);
      button.setAttribute("data-on", "");
    }
    if (this.flagsText) this.flagsText.textContent = this.flagString;
    this.onChange?.();
  }

  fit() {
    this.textarea.style.height = "auto";
    this.textarea.style.height = `${this.textarea.scrollHeight}px`;
  }

  render() {
    if (this.highlight) this.highlight.innerHTML = highlightHTML(this.pattern);
  }

  focus() {
    this.textarea.focus();
  }

  destroy() {
    this.textarea.removeEventListener("input", this.handleInput);
    this.textarea.removeEventListener("keydown", this.handleKeydown);
    this.flagHandlers.forEach((handler, button) => button.removeEventListener("click", handler));
    this.flagHandlers.clear();
  }
}
