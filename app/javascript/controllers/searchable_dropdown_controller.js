import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu", "input", "label", "search", "option"]
  static values = { open: { type: Boolean, default: false } }

  connect() {
    this.clickOutsideHandler = (event) => {
      if (!this.element.contains(event.target)) this.close()
    }
    document.addEventListener("click", this.clickOutsideHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.clickOutsideHandler)
  }

  toggle() {
    this.openValue = !this.openValue
  }

  close() {
    this.openValue = false
  }

  select(event) {
    const value = event.currentTarget.dataset.value
    const label = event.currentTarget.dataset.label

    this.inputTarget.value = value
    this.labelTarget.textContent = label
    this.close()

    this.menuTarget.querySelectorAll("[data-value]").forEach((option) => {
      const check = option.querySelector("[data-check]")
      if (check) check.classList.toggle("invisible", option.dataset.value !== value)
    })
  }

  filter() {
    const query = this.searchTarget.value.toLowerCase()

    this.optionTargets.forEach((option) => {
      const label = option.dataset.label.toLowerCase()
      option.classList.toggle("hidden", !label.includes(query))
    })
  }

  openValueChanged() {
    this.menuTarget.classList.toggle("hidden", !this.openValue)

    if (this.openValue && this.hasSearchTarget) {
      this.searchTarget.value = ""
      this.filter()
      requestAnimationFrame(() => this.searchTarget.focus())
    }
  }
}
